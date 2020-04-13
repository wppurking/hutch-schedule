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
      @broker          = broker
      self.consumers   = consumers
      self.setup_procs = setup_procs
      
      @message_worker = Concurrent::FixedThreadPool.new(Hutch::Config.get(:worker_pool_size))
      @timer_worker   = Concurrent::TimerTask.execute(execution_interval: Hutch::Config.get(:poller_interval)) do
        heartbeat_connection
        retry_buffer_queue
      end
      
      # The queue size maybe the same as channel[prefetch] and every Consumer have it's own buffer queue with the same prefetch size,
      # when the buffer queue have the prefetch size message rabbitmq will stop push message to this consumer but it's ok.
      # The consumer will threshold by the shared redis instace.
      @buffer_queue = ::Queue.new
      @batch_size   = Hutch::Config.get(:poller_batch_size)
      @connected    = Hutch.connected?
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
    
    def handle_message_with_limits(consumer, delivery_info, properties, payload)
      # 1. consumer.limit?
      # 2. yes: make and ConsumerMsg to queue
      # 3. no: post handle
      @message_worker.post do
        if consumer.ratelimit_exceeded?
          @buffer_queue.push(ConsumerMsg.new(consumer, delivery_info, properties, payload))
        else
          # if Hutch disconnect skip do work let message timeout in rabbitmq waiting message push again
          return unless @connected
          consumer.ratelimit_add
          handle_message(consumer, delivery_info, properties, payload)
        end
      end
    end
    
    # 心跳检查 Hutch 的连接
    def heartbeat_connection
      @connected = Hutch.connected?
    end
    
    # 每隔一段时间, 从 buffer queue 中转移任务到执行
    def retry_buffer_queue
      @batch_size.times do
        cmsg = peak
        return if cmsg.blank?
        handle_message_with_limits(cmsg.consumer, cmsg.delivery_info, cmsg.properties, cmsg.payload)
      end
    end
    
    # non-blocking pop message, if empty return nil. other error raise exception
    def peak
      @buffer_queue.pop(true)
    rescue ThreadError => e
      nil if e.to_s == "queue empty"
    end
  end
  
  # Consumer Message wrap rabbitmq message infomation
  class ConsumerMsg
    attr_reader :consumer, :delivery_info, :properties, :payload
    
    def initialize(consumer, delivery_info, properties, payload)
      @consumer      = consumer
      @delivery_info = delivery_info
      @properties    = properties
      @payload       = payload
    end
  end
end



