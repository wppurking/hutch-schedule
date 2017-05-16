require 'hutch/logging'

module Hutch
  module ErrorHandlers
    class MaxRetry
      include Logging

      def initialize
      end

      # TODO: Need to be implement.
      # 1. 获取 hutch 本身记录的 x-death 中的错误次数
      # 2. 从每一个 consumer 身上寻找 max_retry 的次数, 不超过则进行延迟重试
      # 3. 根据错误次数计算类似 active_job 的 exponentially_longer 延迟时间
      #
      # properties.headers example:
      # {
      #   "x-death": [
      #     {
      #       "count": 7,
      #       "exchange": "hutch.topic",
      #       "queue": "retry_queue",
      #       "reason": "expired",
      #       "routing-keys": [
      #         "plan"
      #       ],
      #       "time": "2017-05-13 23:37:15 +0800"
      #     },
      #     {
      #       "count": 7,
      #       "exchange": "hutch",
      #       "original-expiration": "3000",
      #       "queue": "plan_consumer",
      #       "reason": "rejected",
      #       "routing-keys": [
      #         "plan"
      #       ],
      #       "time": "2017-05-13 23:37:05 +0800"
      #     }
      #   ]
      # }
      def handle(properties, payload, consumer, ex)
        raise "Not implement"
      end
    end
  end
end
