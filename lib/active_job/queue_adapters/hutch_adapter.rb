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
          Hutch.publish(HutchAdapter.routing_key(job), job.serialize)
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        interval = [(timestamp - Time.now.utc.to_i), 1.second].max
        enqueue_in(interval, job.serialize, HutchAdapter.routing_key(job))
      end

      def enqueue_in(interval, message, routing_key)
        @monitor.synchronize do
          # must be integer
          props = { expiration: interval.in_milliseconds.to_i }
          Hutch::Schedule.publish(routing_key, message, props)
        end
      end

      # Get an routing_key
      def self.routing_key(job)
        "#{AJ_ROUTING_KEY}.#{job.queue_name}"
      end

      # Register all ActiveJob Class to Hutch. (per queue per consumer)
      def self.register_actice_job_classes
        # TODO: 需要考虑如何将 AJ 的 Proc queue_name 动态注册到 Hutch
        queue_consumers = {}

        Dir.glob(Rails.root.join('app/jobs/**/*.rb')).each { |x| require_dependency x }
        ActiveJob::Base.descendants.each do |job_clazz|
          # Need activeJob instance #queue_name
          job = job_clazz.new
          # Multi queue only have one consumer
          next if queue_consumers.key?(job.queue_name)
          queue_consumers[job.queue_name] = HutchAdapter.dynamic_consumer(job)
          Hutch.register_consumer(queue_consumers[job.queue_name])
        end
      end

      private
      def self.dynamic_consumer(job_instance)
        Class.new do
          extend Hutch::Consumer::ClassMethods

          attr_accessor :broker, :delivery_info

          queue_name job_instance.queue_name
          consume HutchAdapter.routing_key(job_instance)

          def process(job_data)
            ActiveJob::Base.execute(job_data)
          end

          # inspect name
          def inspect
            self.class.name
          end

          define_singleton_method :name do
            "#{job_instance.queue_name}_dynamic_consumer".camelize
          end
        end
      end
    end
  end
end
