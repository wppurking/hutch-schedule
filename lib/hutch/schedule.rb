require 'hutch'
require "hutch/schedule/version"
require 'hutch/logging'

# Help
module Hutch
  # 的看
  module Schedule
    include Logging

    attr_reader :broker, :exchange

    delegate :channel, :config, to: :broker

    # 初始化 schedule
    def initialize(broker)
      @broker = broker
    end

    # 申明 schedule 使用的 ex
    def declare_exchange!
      @exchange = declare_exchange
    end

    def declare_exchange(ch = channel)
      exchange_name    = "#{config[:mq_exchange]}.schedule"
      # TODO: check mq_exchange_options do not exist x-dead-letter-exchange.
      exchange_options = { durable: true, "x-dead-letter-exchange" => config[:mq_exchange] }.merge(config[:mq_exchange_options])
      logger.info "using topic exchange(schedule) '#{exchange_name}'"

      broker.with_bunny_precondition_handler('schedule exchange') do
        ch.topic(exchange_name, exchange_options)
      end
    end

    # 申明 schedule 使用的 queue
    def setup_queue!
      # TODO: add queue ttl
      queue = broker.queue("#{config[:mq_exchange]}_schedule_queue", {})
      # routing all to this queue
      queue.bind(exchange, routing_key: '#')
    end

  end
end
