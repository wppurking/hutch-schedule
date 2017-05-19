require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'hutch'
require 'hutch/enqueue'
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

    def self.connect(broker = Hutch.broker)
      return if core.present?
      @core = Hutch::Schedule::Core.new(broker)
      @core.connect!
      ActiveJob::QueueAdapters::HutchAdapter.register_actice_job_classes if defined?(ActiveJob::QueueAdapters::HutchAdapter)
    end

    def self.core
      @core
    end

    def self.publish(*args)
      core.publish(*args)
    end
  end
end
