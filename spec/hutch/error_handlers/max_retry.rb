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
      def handle(properties, payload, consumer, ex)
        raise "Not implement"
      end
    end
  end
end
