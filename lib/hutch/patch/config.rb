module Hutch
  module Config
    # Hutch Schedule work pool size
    number_setting :worker_pool_size, 20
    
    # Hutch Schedule exceeded checker and poller interval seconds
    # Hutch Worker Pool heartbeat interval (share interval config)
    number_setting :poller_interval, 1
    
    # Hutch Schedule poller batch size
    number_setting :poller_batch_size, 100
    
    # Redis url for ratelimit and unique job
    string_setting :redis_url, "redis://127.0.0.1:6379/0"
    
    # Ratelimit bucket interval
    number_setting :ratelimit_bucket_interval, 1
    
    # Ratelimit redis backend reconnect attempts
    number_setting :ratelimit_redis_reconnect_attempts, 10
    
    initialize(
      worker_pool_size:  20,
      poller_interval:   1,
      poller_batch_size: 100,
      # @see Redis::Client
      redis_url:                          "redis://127.0.0.1:6379/0",
      ratelimit_bucket_interval:          1,
      ratelimit_redis_reconnect_attempts: 10
    )
    define_methods
  end
end
