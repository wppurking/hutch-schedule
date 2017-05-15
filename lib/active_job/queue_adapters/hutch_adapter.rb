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

      # 不适用 Consumer 的 enqueue, 无需每次重复计算
      def enqueue(job) #:nodoc:
        @monitor.synchronize do
          # 将整个 job 的 data 变为 hash 发布出去
          Hutch.publish(routing_key(job), job.serialize)
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        interval = [(timestamp - Time.now.utc.to_i), 1.second].max
        enqueue_in(interval, job.serialize, routing_key(job))
      end

      # 不适用 Consumer 的 enqueue, 无需每次重复计算
      def enqueue_in(interval, message, routing_key)
        @monitor.synchronize do
          # 必须是 integer
          props = { expiration: interval.in_milliseconds.to_i }
          Hutch::Schedule.publish(routing_key, message, props)
        end
      end

      # 计算 routing_key
      def routing_key(job)
        "#{AJ_ROUTING_KEY}.#{job.queue_name}"
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
