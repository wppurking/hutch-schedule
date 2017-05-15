require 'active_support/concern'
require 'hutch/schedule'

module Hutch
  # 如果需要增加让 Consumer Enqueue 的动作, 那么则 include 这个 Module
  module Enqueue
    extend ActiveSupport::Concern

    # Add Consumer methods
    class_methods do
      # 正常的发布 consumer 对应 routing key 的消息
      def enqueue(message)
        Hutch.publish(enqueue_routing_key, message)
      end

      # publish message at delay
      # interval: 推迟的时间
      # message: 具体的消息
      def enqueue_at(interval, message)
        props = { expiration: interval.in_milliseconds }
        Hutch::Schedule.publish(enqueue_routing_key, message, props)
      end

      # routing_key: 目的为将 Message 发送给 RabbitMQ 那么使用其监听的任何一个 routing_key 都可以发送
      def enqueue_routing_key
        raise "Routing Keys is not set!" if routing_keys.size < 1
        routing_keys.first
      end
    end
  end
end

