require 'hutch'
require "hutch-schedule/version"
require 'active_support/core_ext/module/delegation'

# Help
module HutchSchedule
  # 共享 Hutch::Broker 实例的所有东西
  class Core

    attr_reader :broker, :exchange

    delegate :channel, :config, :connection, :logger, :with_bunny_precondition_handler, to: :broker

    # 初始化 schedule
    def initialize(broker)
      raise "Broker can`t be nil" if broker.blank?
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
      # TODO: 将 Queue 的 ttl 抽取成为参数
      queue = broker.queue("#{config[:mq_exchange]}_schedule_queue", { 'x-message-ttl': 30.days.in_milliseconds })
      # routing all to this queue
      queue.bind(exchange, routing_key: '#')
    end

    # Schedule broker 自己的 publish 方法
    def publish(*args)
      @publisher.publish(*args)
    end
  end
end
