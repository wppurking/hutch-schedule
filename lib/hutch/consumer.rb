require 'set'

module Hutch
  # Include this module in a class to register it as a consumer. Consumers
  # gain a class method called `consume`, which should be used to register
  # the routing keys a consumer is interested in.
  module Consumer

    # Add Consumer methods
    module ClassMethods
      # 正常的发布 consumer 对应 routing key 的消息
      def enqueue(message)
        Hutch.publish(enqueue_routing_key, message)
      end

      # publish message at delay
      # interval: 推迟的时间
      # message: 具体的消息
      def enqueue_at(interval, message)
        props = { expiration: interval.in_milliseconds }
        Hutch.schedule(enqueue_routing_key, message, props)
      end

      # routing_key: 目的为将 Message 发送给 RabbitMQ 那么使用其监听的任何一个 routing_key 都可以发送
      def enqueue_routing_key
        raise "Routing Keys is not set!" if routing_keys.size < 1
        routing_keys.first
      end
    end
  end
end

