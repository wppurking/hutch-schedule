# open class for Hutch
module Hutch

  # schedule message
  def self.schedule(*args)
    broker.schedule.publish(*args)
  end
end
