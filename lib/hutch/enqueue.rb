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
      # interval: delay interval
      # message: publish message
      def enqueue_in(interval, message, props = {})
        properties = props.merge(expiration: interval.in_milliseconds.to_i)
        Hutch::Schedule.publish(enqueue_routing_key, message, properties)
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
    end
  end
end

