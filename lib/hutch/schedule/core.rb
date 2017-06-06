require 'active_support/dependencies/autoload'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/module/delegation'

module Hutch
  module Schedule
    class Core

      attr_reader :broker, :exchange

      delegate :channel, :connection, :logger, to: :broker

      def initialize(broker)
        raise "Broker can`t be nil" if broker.blank?
        @broker = broker
      end

      # Use the config with Hutch::Broker instance
      def config
        broker.instance_variable_get(:@config)
      end

      # Becareful with the sequence of initialize
      def connect!
        declare_exchange!
        declare_publisher!
        setup_queue!
      end

      def declare_publisher!
        @publisher = Hutch::Publisher.new(connection, channel, exchange, config)
      end

      # The exchange used by Hutch::Schedule
      def declare_exchange!
        @exchange = declare_exchange
      end

      def declare_exchange(ch = channel)
        exchange_name    = "#{config[:mq_exchange]}.schedule"
        exchange_options = { durable: true }.merge(config[:mq_exchange_options])
        logger.info "using topic exchange(schedule) '#{exchange_name}'"

        broker.send(:with_bunny_precondition_handler, 'schedule exchange') do
          ch.topic(exchange_name, exchange_options)
        end
      end

      # The queue used by Hutch::Schedule
      def setup_queue!
        # TODO: extract the ttl to config params
        props = { 'x-message-ttl': 30.days.in_milliseconds, 'x-dead-letter-exchange': config[:mq_exchange] }
        queue = broker.queue("#{config[:mq_exchange]}_schedule_queue", props)

        # routing all to this queue
        queue.unbind(exchange, routing_key: '#')
        queue.bind(exchange, routing_key: '#')
      end

      # Schedule`s publisher, publish the message to schedule topic exchange
      def publish(*args)
        @publisher.publish(*args)
      end
    end
  end
end
