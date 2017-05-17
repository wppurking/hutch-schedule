require "hutch/schedule"

module ActiveJob
  module QueueAdapters
    # == Hutch adapter for Active Job
    #
    # Read more about Hutch {here}[https://github.com/gocardless/hutch].
    #
    #   Rails.application.config.active_job.queue_adapter = :hutch
    class HutchAdapter
      # All activejob Message will routing to one RabbitMQ Queue.
      # Because Hutch will one Consumer per Queue
      AJ_ROUTING_KEY = "active_job"

      def initialize
        @monitor = Monitor.new
      end

      def enqueue(job) #:nodoc:
        @monitor.synchronize do
          # publish all job data to hutch
          Hutch.publish(routing_key(job), job.serialize)
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        interval = [(timestamp - Time.now.utc.to_i), 1.second].max
        enqueue_in(interval, job.serialize, routing_key(job))
      end

      def enqueue_in(interval, message, routing_key)
        @monitor.synchronize do
          # must be integer
          props = { expiration: interval.in_milliseconds.to_i }
          Hutch::Schedule.publish(routing_key, message, props)
        end
      end

      # Get an routing_key
      def routing_key(job)
        "#{AJ_ROUTING_KEY}.#{job.queue_name}"
      end

      class JobWrapper #:nodoc:
        include Hutch::Consumer
        # Consume All active_job.# routing_key message to this consume`s queue
        consume "#{HutchAdapter::AJ_ROUTING_KEY}.#"

        def process(job_data)
          Base.execute job_data
        end
      end
    end
  end
end
