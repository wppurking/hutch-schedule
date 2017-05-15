require 'active_support/core_ext/module/delegation'
require 'hutch'
require 'hutch/enqueue'
require 'hutch/schedule/core'

# gem 的核心入口文件
module Hutch
  # 在 Hutch 下的独立的 Schedule module, 负责与 schedule 相关的 publish
  module Schedule

    def self.connect(broker)
      return if core.present?
      @core = Hutch::Schedule::Core.new(broker)
      @core.connect!
    end

    def self.core
      @core
    end

    def self.publish(*args)
      core.publish(*args)
    end
  end
end
