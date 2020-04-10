module Hutch
  module Config
    # Hutch Schedule work pool size
    number_setting :worker_pool_size, 20
    
    # Hutch Schedule exceeded checker and poller interval seconds
    number_setting :poller_interval, 1
    
    # Hutch Schedule poller batch size
    number_setting :poller_batch_size, 100
    
    initialize(
      worker_pool_size:  20,
      poller_interval:   1,
      poller_batch_size: 100
    )
  end
end
