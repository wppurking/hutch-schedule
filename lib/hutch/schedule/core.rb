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

      # Becareful with the sequence of initialize
      def connect!
        declare_delay_exchange!
        declare_publisher!
        setup_delay_queues!
      end

      def declare_publisher!
        @publisher = Hutch::Publisher.new(connection, channel, exchange)
      end

      # The exchange used by Hutch::Schedule
      def declare_delay_exchange!
        @exchange = declare_delay_exchange
      end

      def declare_delay_exchange(ch = channel)
        exchange_name = "#{Hutch::Config.get(:mq_exchange)}.schedule"
        exchange_options = { durable: true }.merge(Hutch::Config.get(:mq_exchange_options))
        logger.info "using topic exchange(schedule) '#{exchange_name}'"

        broker.send(:with_bunny_precondition_handler, 'schedule exchange') do
          ch.topic(exchange_name, exchange_options)
        end
      end

      # The queue used by Hutch::Schedule
      def setup_delay_queues!
        DELAY_QUEUES.map { |suffix| setup_delay_queue!(suffix) }
      end

      def setup_delay_queue!(suffix)
        # TODO: extract the ttl to config params
        props = { :'x-message-ttl' => 30.days.in_milliseconds, :'x-dead-letter-exchange' => Hutch::Config.get(:mq_exchange) }
        queue = broker.queue(Hutch::Schedule.delay_queue_name(suffix), props)

        # routing all to this queue
        queue.unbind(exchange, routing_key: Hutch::Schedule.delay_routing_key(suffix))
        queue.bind(exchange, routing_key: Hutch::Schedule.delay_routing_key(suffix))
      end

      # Schedule`s publisher, publish the message to schedule topic exchange
      def publish(*args)
        @publisher.publish(*args)
      end
    end
  end
end
