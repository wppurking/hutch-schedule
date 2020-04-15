require 'concurrent'

module Hutch
  # Monkey patch worker. 因为 hutch 是借用的底层的 bunny 的 ConsumerWorkPool 来完成的并发任务处理,
  # 但这个 Pool 太过于通用, 而我们需要针对 rabbitmq 传入过来的 Message 进行处理, 需要在任务执行的过程中
  # 添加额外的处理信息, 所以我们不由 ConsumerWorkPool 来处理任务, 改为由 ConsumerWorkPool 执行一次任务提交,
  # 由 Bunny::ConsumerWorkPool 将需要执行的 block 提交给自己的 WorkerPool 来进行最终执行.
  # 因为 RabbitMQ 队列中的任务是需要手动 Ack 才会标记完成, 并且根据 Channel 会有 Prefetch, 所以结合这两个特性
  # 则可以利用本地进程中的 Queue 进行缓存任务, 只要没有执行会有 Prefetch 控制当前节点缓存的总任务数, 根据 Ack 会
  # 明确告知 RabbitMQ 此任务完成.
  class Worker
    def initialize(broker, consumers, setup_procs)
      raise "use Hutch::Schedule must set an positive channel_prefetch" if Hutch::Config.get(:channel_prefetch) < 1
      @broker          = broker
      self.consumers   = consumers
      self.setup_procs = setup_procs
      
      @message_worker = Concurrent::FixedThreadPool.new(Hutch::Config.get(:worker_pool_size))
      @timer_worker   = Concurrent::TimerTask.execute(execution_interval: Hutch::Config.get(:poller_interval)) do
        # all chekcer in the same thread
        heartbeat_connection
        flush_to_retry
        retry_buffer_queue
      end
      
      # The queue size maybe the same as channel[prefetch] and every Consumer shared one buffer queue with the
      # same prefetch size, when current consumer have unack messages reach the prefetch size rabbitmq will stop push
      # message to this consumer.
      # Because the buffer queue is shared by all consumers so the max queue size is [prefetch * consumer count],
      # if prefetch is 20 and have 30 consumer the max queue size is  20 * 30 = 600.
      @buffer_queue    = ::Queue.new
      @batch_size      = Hutch::Config.get(:poller_batch_size)
      @connected       = Hutch.connected?
      @last_flush_time = Time.now.utc
    end
    
    # Stop a running worker by killing all subscriber threads.
    # Stop two thread pool
    def stop
      @timer_worker.shutdown
      @message_worker.shutdown
      @broker.stop
    end
    
    # Bind a consumer's routing keys to its queue, and set up a subscription to
    # receive messages sent to the queue.
    def setup_queue(consumer)
      logger.info "setting up queue: #{consumer.get_queue_name}"
      
      queue = @broker.queue(consumer.get_queue_name, consumer.get_arguments)
      @broker.bind_queue(queue, consumer.routing_keys)
      
      queue.subscribe(consumer_tag: unique_consumer_tag, manual_ack: true) do |*args|
        delivery_info, properties, payload = Hutch::Adapter.decode_message(*args)
        handle_message_with_limits(consumer, delivery_info, properties, payload)
      end
    end
    
    # cmsg: ConsumerMsg
    def handle_cmsg_with_limits(cmsg)
      return if cmsg.blank?
      # 正常的任务处理 ratelimit 的处理逻辑, 如果有限制那么就进入 buffer 缓冲
      consumer = cmsg.consumer
      @message_worker.post do
        if consumer.ratelimit_exceeded?(cmsg.message)
          @buffer_queue.push(cmsg)
        else
          # if Hutch disconnect skip do work let message timeout in rabbitmq waiting message push again
          return unless @connected
          consumer.ratelimit_add(cmsg.message)
          handle_cmsg(*cmsg.handle_cmsg_args)
        end
      end
    
    end
    
    def handle_message_with_limits(consumer, delivery_info, properties, payload)
      handle_cmsg_with_limits(consumer_msg(consumer, delivery_info, properties, payload))
    end
    
    # change args to message reuse the code from #handle_message
    def consumer_msg(consumer, delivery_info, properties, payload)
      serializer = consumer.get_serializer || Hutch::Config[:serializer]
      logger.debug {
        spec = serializer.binary? ? "#{payload.bytesize} bytes" : "#{payload}"
        "message(#{properties.message_id || '-'}): " +
          "routing key: #{delivery_info.routing_key}, " +
          "consumer: #{consumer}, " +
          "payload: #{spec}"
      }
      
      ConsumerMsg.new(consumer, Hutch::Message.new(delivery_info, properties, payload, serializer))
    end
    
    def handle_cmsg(consumer, delivery_info, properties, payload, message)
      consumer_instance = consumer.new.tap { |c| c.broker, c.delivery_info = @broker, delivery_info }
      with_tracing(consumer_instance).handle(message)
      @broker.ack(delivery_info.delivery_tag)
    rescue => ex
      acknowledge_error(delivery_info, properties, @broker, ex)
      handle_error(properties, payload, consumer, ex)
    end
    
    
    # 心跳检查 Hutch 的连接
    def heartbeat_connection
      @connected = Hutch.connected?
    end
    
    # 每隔一段时间, 从 buffer queue 中转移任务到执行, interval 比较短的会立即执行掉
    def retry_buffer_queue
      @batch_size.times do
        cmsg = peak
        return if cmsg.blank?
        handle_cmsg_with_limits(cmsg)
      end
    end
    
    # 对于 rate 间隔比较长的, 不适合一直存储在 buffer 中, 所以需要根据 interval 的值将长周期的 message 重新入队给 RabbitMQ 让其进行
    # 等待, 但同时不可以让其直接 Requeue, 这样会导致频繁的与 RabbitMQ 来往交换. 需要让消息根据周期以及执行次数逐步拉长等待, 直到最终最长
    # 时间的等待.
    #
    # 有下面几个要求:
    #  - 在 retry_buffer_queue 之前调用
    #  - 整个方法调用时间长度需要在 1s 之内
    def flush_to_retry
      now = Time.now.utc
      # 现在为每 10s flush 一次
      if now - @last_flush_time >= 5
        @buffer_queue.size.times do
          cmsg = peak
          break if cmsg.blank?
          # 如果没有被处理, 重新放回 buffer
          @buffer_queue.push(cmsg) unless cmsg.enqueue_in_or_not
        end
        @last_flush_time = now
      end
    end
    
    # non-blocking pop message, if empty return nil. other error raise exception
    def peak
      @buffer_queue.pop(true)
    rescue ThreadError => e
      nil if e.to_s == "queue empty"
    end
  end
  
  # Consumer Message wrap Hutch::Message and Consumer
  class ConsumerMsg
    attr_reader :consumer, :message
    
    def logger
      Hutch::Logging.logger
    end
    
    def initialize(consumer, message)
      @consumer = consumer
      @message  = message
    end
    
    def handle_cmsg_args
      [consumer, message.delivery_info, message.properties, message.payload, message]
    end
    
    # if delays > 10s then let the message to rabbitmq to delay and enqueue again instead of rabbitmq reqneue
    def enqueue_in_or_not
      interval = consumer.interval(message)
      # interval 小于 5s, 的则不会传, 在自己的 buffer 中等待
      return false if interval < 5
      # 等待时间过长的消息, 交给远端的 rabbitmq 去进行等待, 不占用 buffer 空间
      # TODO: 如果数据量特别大, 但 ratelimit 特别严格, 那么也会变为固定周期的积压, 需要增加对执行次数的记录以及延长
      # TODO: 市场 30s 执行一次的任务, 积累了 200 个, 那么这个积压会越来越多, 直到保持到一个 RabbitMQ 与 hutch 之间的最长等待周期, 会一直空转
      #  - 要么增加对执行次数的考虑, 拉长延长. 但最终会有一个最长的延长 10800 (3h), 这个问题最终仍然会存在
      #  - 设置延长多长之后, 就舍弃这个任务, 因为由于 ratelimit 的存在, 但又持续的积压, 不可能处理完这个任务
      Hutch.broker.ack(message.delivery_info.delivery_tag)
      consumer.enqueue_in(interval, message.body, message.properties.to_hash)
    end
  end
end



