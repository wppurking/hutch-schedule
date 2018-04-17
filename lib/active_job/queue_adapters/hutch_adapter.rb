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
      @@queue_consumers = {}

      def initialize
        @monitor = Monitor.new
      end

      def enqueue(job) #:nodoc:
        @monitor.synchronize do
          @@queue_consumers[job.queue_name].enqueue(job.serialize)
        end
      end

      def enqueue_at(job, timestamp) #:nodoc:
        @monitor.synchronize do
          @@queue_consumers[job.queue_name].enqueue_at(timestamp, job.serialize)
        end
      end

      # Get an routing_key
      def self.routing_key(job)
        "#{AJ_ROUTING_KEY}.#{job.queue_name}"
      end

      # Register all ActiveJob Class to Hutch. (per queue per consumer)
      def self.register_actice_job_classes
        # TODO: 需要考虑如何将 AJ 的 Proc queue_name 动态注册到 Hutch
        Dir.glob(Rails.root.join('app/jobs/**/*.rb')).each { |x| require_dependency x }
        ActiveJob::Base.descendants.each do |job_clazz|
          # Need activeJob instance #queue_name
          job = job_clazz.new
          # Multi queue only have one consumer
          next if @@queue_consumers.key?(job.queue_name)
          @@queue_consumers[job.queue_name] = HutchAdapter.dynamic_consumer(job)
          Hutch.register_consumer(@@queue_consumers[job.queue_name])
        end
      end

      private
      def self.dynamic_consumer(job_instance)
        Class.new do
          # don't include Hutch::Consumer, we should change the name of consumer to registe
          extend Hutch::Consumer::ClassMethods
          include Hutch::Enqueue

          attr_accessor :broker, :delivery_info

          queue_name job_instance.queue_name
          consume HutchAdapter.routing_key(job_instance)

          def process(job_data)
            ActiveJob::Base.execute(job_data)
          end

          define_singleton_method :name do
            "#{job_instance.queue_name}_dynamic_consumer".camelize
          end

          # inspect name
          define_singleton_method :inspect do
            "#{job_instance.queue_name}_dynamic_consumer".camelize
          end

          define_singleton_method :to_s do
            "#{job_instance.queue_name}_dynamic_consumer".camelize
          end
        end
      end
    end
  end
end
