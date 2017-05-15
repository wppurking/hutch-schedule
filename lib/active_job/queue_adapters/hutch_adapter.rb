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
      def initialize
        @monitor = Monitor.new
      end

      def enqueue(job) #:nodoc:
        @monitor.synchronize do
          JobWrapper.consume *job.routing_keys.to_a
          # 将整个 job 的 data 变为 hash 发布出去
          JobWrapper.enqueue job.serialize
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        @monitor.synchronize do
          JobWrapper.consume *job.routing_keys.to_a
          JobWrapper.enqueue_at(timestamp, job.serialize)
        end
      end

      class JobWrapper #:nodoc:
        include Hutch::Consumer
        include Hutch::Enqueue

        def process(job_data)
          # 执行 ActiveJob 的 Base, 将整个 job 的 data 传过去, 让其进行反序列化, 组织成参数等等
          Base.execute job_data
        end
      end
    end
  end
end
