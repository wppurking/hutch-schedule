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
        Dir.glob(Rails.root.join('app/jobs/**/*.rb')).each { |x| require_dependency x }
        ActiveJob::Base.descendants.each do |job|
          Hutch.consumers << Class.new do
            extend Hutch::Consumer::ClassMethods

            attr_accessor :broker, :delivery_info

            queue_name job.queue_name
            consume HutchAdapter.routing_key(job)

            define_method :process do |job_data|
              ActiveJob::Base.execute(job_data)
            end
          end
        end
      end
    end
  end
end
