require 'hutch'
require 'hutch/enqueue'
require 'active_support/core_ext/module/delegation'
require 'hutch-schedule/core'
require "hutch-schedule/version"

# Help
module HutchSchedule
  def self.connect(broker)
    return if core.present?
    @core = HutchSchedule::Core.new(broker)
    @core.connect!
  end

  def self.core
    @core
  end

  def self.publish(*args)
    core.publish(*args)
  end
end
