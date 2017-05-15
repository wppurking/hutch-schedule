require 'active_support/core_ext/module/delegation'
require 'hutch/schedule/core'

# Help
module Hutch::Schedule

  def self.connect(broker)
    return if core.present?
    @core = Hutch::Schedule::Core.new(broker)
    @core.connect!
  end

  def self.core
    @core
  end

  def self.publish(*args)
    core.publish(*args)
  end
end
