require 'hutch'
require "hutch/schedule/version"
require 'hutch/logging'

# Help
module Hutch
  # 共享 Hutch::Broker 实例的所有东西
  module Schedule

    attr_reader :broker, :exchange

    delegate :channel, :config, :connection, :logger, :with_bunny_precondition_handler, to: :broker

    # 初始化 schedule
    def initialize(broker)
      @broker = broker
    end

    def setup!
      declare_publisher!
      declare_exchange!
      setup_queue!
    end

    def declare_publisher!
      @publisher = Hutch::Publisher.new(connection, channel, exchange, config)
    end

    # 申明 schedule 使用的 ex
    def declare_exchange!
      @exchange = declare_exchange
    end

    def declare_exchange(ch = channel)
      exchange_name    = "#{config[:mq_exchange]}.schedule"
      # TODO: 检查 mq_exchange_options 中的信息, 确保不会覆盖 x-dead-letter-exchange 的参数
      exchange_options = {
        durable:                  true,
        'x-dead-letter-exchange': config[:mq_exchange] }.merge(config[:mq_exchange_options])
      logger.info "using topic exchange(schedule) '#{exchange_name}'"

      with_bunny_precondition_handler('schedule exchange') do
        ch.topic(exchange_name, exchange_options)
      end
    end

    # 申明 schedule 使用的 queue
    def setup_queue!
      # TODO: 为 Queue 增加 TTL, 避免队列一直积压
      queue = broker.queue("#{config[:mq_exchange]}_schedule_queue", {})
      # routing all to this queue
      queue.bind(exchange, routing_key: '#')
    end

    def publish(*args)
      @publisher.publish(*args)
    end
  end
end
