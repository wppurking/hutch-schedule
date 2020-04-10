require 'concurrent'

module Hutch
  # Monkey patch worker. 因为 hutch 是借用的底层的 bunny 的 ConsumerWorkPool 来完成的并发任务处理,
  # 但这个 Pool 太过于通用, 而我们需要针对 rabbitmq 传入过来的 Message 进行处理, 需要在任务执行的过程中
  # 添加额外的处理信息, 所以我们不由 ConsumerWorkPool 来处理任务, 改为由 ConsumerWorkPool 执行一次任务提交,
  # 由 Bunny::ConsumerWorkPool 将需要执行的 block 提交给自己的 WorkerPool 来进行最终执行
  class Worker
    def initialize(broker, consumers, setup_procs)
      @broker          = broker
      self.consumers   = consumers
      self.setup_procs = setup_procs
      
      # TODO: 将这个线程变量暴露出去
      @message_worker = Concurrent::FixedThreadPool.new(20)
      # TODO: 提取成为参数, 每 5s 执行一次任务
      @timer_worker = Concurrent::TimerTask.execute(execution_interval: 5) { retry_buffer_queue }
      @buffer_queue = ::Queue.new
    end
    
    # Bind a consumer's routing keys to its queue, and set up a subscription to
    # receive messages sent to the queue.
    def setup_queue(consumer)
      logger.info "setting up queue: #{consumer.get_queue_name}"
      
      queue = @broker.queue(consumer.get_queue_name, consumer.get_arguments)
      @broker.bind_queue(queue, consumer.routing_keys)
      
      queue.subscribe(consumer_tag: unique_consumer_tag, manual_ack: true) do |*args|
        delivery_info, properties, payload = Hutch::Adapter.decode_message(*args)
        # TODO: 队列本身的 block 只是提交任务给另外的 ThreadPool, 但需要暴露参数, 给到特制的 ThreadPool 拥有能力进行 ratelimit
        handle_message_with_limits(consumer, delivery_info, properties, payload)
      end
    end
    
    def handle_message_with_limits(consumer, delivery_info, properties, payload)
      puts 'handle_message_with_limits.......'
      handle_message(consumer, delivery_info, properties, payload)
    end
    
    def retry_buffer_queue
      puts 'retry_buffer_queue'
    end
  end
end
