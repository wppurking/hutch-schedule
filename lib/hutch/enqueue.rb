require 'active_support/concern'
require 'active_support/core_ext/numeric/time'
require 'hutch/schedule'

module Hutch
  # If consumer need `enqueue`, just include this module
  module Enqueue
    extend ActiveSupport::Concern

    # Add Consumer methods
    class_methods do
      # Publish the message to this consumer with one routing_key
      def enqueue(message)
        Hutch.publish(enqueue_routing_key, message)
      end

      # publish message at a delay times
      # interval: delay interval seconds
      # message: publish message
      def enqueue_in(interval, message, props = {})
        # TODO: 超过 3h 的延迟也会接收, 但是不会延迟那么长时间, 但给予 warn
        delay_seconds = delay_seconds_level(interval)

        # 设置固定的延迟, 利用 headers 中的 CC, 以及区分的 topic, 将消息重新投递进入队列
        properties = props.merge(expiration: (delay_seconds * 1000).to_i, headers: { :'CC' => [enqueue_routing_key] })
        delay_routing_key = Hutch::Schedule.delay_routing_key("#{delay_seconds}s")

        Hutch::Schedule.publish(delay_routing_key, message, properties)
      end

      # delay at exatly time point
      def enqueue_at(time, message, props = {})
        # if time is early then now then just delay 1 second
        interval = [(time.utc - Time.now.utc), 1.second].max
        enqueue_in(interval, message, props)
      end

      # routing_key: the purpose is to send message to hutch exchange and then routing to the correct queue,
      # so can use any of them routing_key that the consumer is consuming.
      def enqueue_routing_key
        raise "Routing Keys is not set!" if routing_keys.size < 1
        routing_keys.to_a.last
      end

      def attempts(times)
        @max_retries = [times, 0].max
      end

      def max_attempts
        @max_retries || 0
      end

      # 计算 delay 的 level
      # 5s 10s 20s 30s
      # 60s 120s 180s 240s 300s 360s 420s 480s 540s 600s 1200s 1800s 2400s
      # 3600s 7200s 10800s
      def delay_seconds_level(delay_seconds)
        case delay_seconds
        when 0..5 # 5s
          5
        when 5..10 # 10s
          10
        when 10..20 # 20s
          20
        when 20..30 # 30s
          30
        when 30..60 # 60s
          60
        when 60..120 # 120s
          120
        when 120..180 # 180s
          180
        when 180..240 # 240s
          240
        when 240..300 # 300s
          300
        when 300..360 # 360s
          360
        when 360..420 # 420s
          420
        when 420..480 # 480s
          480
        when 480..540 # 540s
          540
        when 540..600 # 600s
          600
        when 600..1200 # 1200s
          1200
        when 1200..1800 # 1800s
          1800
        when 1800..2400 # 2400s
          2400
        when 2400..3000 # 3000s
          3000
        when 3000..3600 # 3600s
          3600
        when 3600..7200 # 7200s
          7200
        when 7200..10800 # 10800s
          10800
        else
          10800
        end
      end
    end
  end
end

