require 'active_support/concern'
require 'hutch/schedule'
require 'ratelimit'

module Hutch
  # If consumer need `threshold`, just include this module. (included with Hutch::Enqueue)
  module Threshold
    extend ActiveSupport::Concern
    
    # Add Consumer methods
    class_methods do
      # 限流速度:
      #  context: 可选的上下文, 默认为 default
      #  rate: 数量
      #  interval: 间隔
      #
      #  block: 采用 lambada 的方式计算, 但需要返回三个参数:
      #   - context: 当前约束的上下文
      #   - rate: 数量
      #   - interval: 间隔
      # 例如:
      #  - rate: 1, interval: 1, 每秒 1 个
      #  - rate: 30, interval: 1, 每秒 30 个
      #  - rate: 30, interval: 5, 每 5 s, 30 个
      def threshold(args, &block)
        @block_given = block_given?
        if @block_given
          @threshold_block = block
        else
          raise "need args or block" if args.blank?
          raise "args need hash type" if args.class != Hash
          args.symbolize_keys!
          @context  = args[:context].presence || "default"
          @rate     = args[:rate]
          @interval = args[:interval]
        end
        @rate_limiter = Ratelimit.new(self.class.name)
      end
      
      # 判断是否超期
      def ratelimit_exceeded?
        @rate_limiter.exceeded?(_context, threshold: _rate, interval: _interval)
      end
      
      # 增加一次调用
      def ratelimit_add
        @rate_limiter.add(_context)
      end
      
      def _context
        @block_given ? @threshold_block.call[:context] : @context
      end
      
      def _rate
        @block_given ? @threshold_block.call[:rate] : @rate
      end
      
      def _interval
        @block_given ? @threshold_block.call[:interval] : @interval
      end
    end
  end
end

