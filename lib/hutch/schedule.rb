require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'hutch'
require 'hutch/enqueue'
require 'hutch/error_handlers/max_retry'
require 'hutch/schedule/core'

# If ActiveJob is requried then required the adapter
if defined?(ActiveJob)
  require 'active_job/queue_adapters/hutch_adapter'
end

module Hutch
  # Hutch::Schedule, just an addon to deal with the schedule exchange.
  # If you want use it, just do `Hutch::Schedule.connect(Hutch.broker)` to initialize it
  # and then just use like Hutch to publish message `Hutch::Schedule.publish`
  module Schedule
    DELAY_QUEUES = %w(5s 10s 30s 60s 120s 180s 3600s 7200s 10800s)

    class << self
      def connect
        return if core.present?
        Hutch.connect unless Hutch.connected?
        @core = Hutch::Schedule::Core.new(Hutch.broker)
        @core.connect!
        ActiveJob::QueueAdapters::HutchAdapter.register_actice_job_classes if defined?(ActiveJob::QueueAdapters::HutchAdapter)
      end

      def core
        @core
      end

      def publish(*args)
        core.publish(*args)
      end

      # 进入后续可选队列的 routing key
      def delay_routing_key(suffix)
        "#{Hutch::Config.get(:mq_exchange)}.schedule.#{suffix}"
      end

      def delay_queue_name(suffix)
        "#{Hutch::Config.get(:mq_exchange)}_delay_queue_#{suffix}"
      end
    end
  end
end
