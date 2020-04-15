require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'hutch'
require 'hutch/patch/config'
require 'hutch/patch/worker'
require 'hutch/schedule/core'
require 'hutch/enqueue'
require 'hutch/threshold'
require 'hutch/error_handlers/max_retry'

# If ActiveJob is requried then required the adapter
if defined?(ActiveJob)
  require 'active_job/queue_adapters/hutch_adapter'
end

module Hutch
  # Hutch::Schedule, just an addon to deal with the schedule exchange.
  # If you want use it, just do `Hutch::Schedule.connect(Hutch.broker)` to initialize it
  # and then just use like Hutch to publish message `Hutch::Schedule.publish`
  module Schedule
    
    # fixed delay levels
    # seconds(4): 5s, 10s, 20s, 30s
    # minutes(14): 1m, 2m, 3m, 4m, 5m, 6m, 7m, 8m, 9m, 10m, 20m, 30m, 40m, 50m
    # hours(3): 1h, 2h, 3h
    DELAY_QUEUES = %w(5s 10s 20s 30s 60s 120s 180s 240s 300s 360s 420s 480s 540s 600s 1200s 1800s 2400s 3000s 3600s 7200s 10800s)
    
    class << self
      def connect
        ActiveJob::QueueAdapters::HutchAdapter.register_actice_job_classes if defined?(ActiveJob::QueueAdapters::HutchAdapter)
        
        return if core.present?
        Hutch.connect
        @core = Hutch::Schedule::Core.new(Hutch.broker)
        @core.connect!
      end
      
      def disconnect
        Hutch.disconnect if Hutch.connected?
        @core = nil
      end
      
      def core
        @core
      end
      
      # redis with namespace
      def ns
        @redis ||= Redis::Namespace.new(:hutch, redis: Redis.new(
          url: Hutch::Config.get(:redis_url),
          # https://github.com/redis/redis-rb#reconnections
          # retry 10 times total cost 10 * 30 = 300s
          reconnect_attempts:  Hutch::Config.get(:ratelimit_redis_reconnect_attempts),
          :reconnect_delay     => 3,
          :reconnect_delay_max => 30.0,
        ))
      end
      
      # all Consumers that use threshold module shared the same redis instance
      def redis
        ns.redis
      end
      
      
      def publish(*args)
        core.publish(*args)
      end
      
      # fixed delay level queue's routing_key
      def delay_routing_key(suffix)
        "#{Hutch::Config.get(:mq_exchange)}.schedule.#{suffix}"
      end
      
      def delay_queue_name(suffix)
        "#{Hutch::Config.get(:mq_exchange)}_delay_queue_#{suffix}"
      end
    end
  end
end
