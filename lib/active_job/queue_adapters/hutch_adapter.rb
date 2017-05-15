require "hutch/schedule"

module ActiveJob
  module QueueAdapters
    # == Hutch adapter for Active Job
    #
    # 简单高效的消息服务方案, Hutch 以多线程的方式处理 RabbitMQ 中的不同 Queue 的 Message.
    #
    # Read more about Hutch {here}[https://github.com/gocardless/hutch].
    #
    #   Rails.application.config.active_job.queue_adapter = :hutch
    class HutchAdapter
      # 需要将 activejob 使用的队列全部 routing 到一个 rabbitmq 的 queue 中
      AJ_ROUTING_KEY = "active_job"

      def initialize
        @monitor = Monitor.new
      end

      def enqueue(job) #:nodoc:
        @monitor.synchronize do
          JobWrapper.consume "#{AJ_ROUTING_KEY}.#{job.queue_name}"
          # 将整个 job 的 data 变为 hash 发布出去
          JobWrapper.enqueue job.serialize
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        @monitor.synchronize do
          JobWrapper.consume "#{AJ_ROUTING_KEY}.#{job.queue_name}"
          JobWrapper.enqueue_at(timestamp, job.serialize)
        end
      end

      class JobWrapper #:nodoc:
        include Hutch::Consumer
        include Hutch::Enqueue
        # 给 ActiveJob 使用的一个大队列
        consume "#{HutchAdapter::AJ_ROUTING_KEY}.#"

        def process(job_data)
          # 执行 ActiveJob 的 Base, 将整个 job 的 data 传过去, 让其进行反序列化, 组织成参数等等
          Base.execute job_data
        end
      end
    end
  end
end
