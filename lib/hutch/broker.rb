require 'active_support/core_ext/object/blank'

# Hutch Open Class
module Hutch
  # Hutch Open Class
  class Broker

    attr_reader :schedule

    def disconnect
      @channel.close if @channel
      @connection.close if @connection
      @channel    = nil
      @connection = nil
      @exchange   = nil
      @api_client = nil
    end

    # Connect to RabbitMQ via AMQP
    #
    # This sets up the main connection and channel we use for talking to
    # RabbitMQ. It also ensures the existence of the exchange we'll be using.
    def set_up_amqp_connection
      open_connection!
      open_channel!
      declare_exchange!
      declare_publisher!

      # Hack
      set_up_schedule!
    end

    def set_up_schedule!
      @schedule = Hutch::Schedule.new(self)
      schedule.declare_exchange!
      schedule.setup_queue!
    end

    def publish(*args)
      @publisher.publish(*args)
    end
  end
end
