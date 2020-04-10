require "spec_helper"

# 需要真正的 rabbitmq 启动
RSpec.describe Hutch::Schedule::Core do
  it "has a version number" do
    expect(Hutch::Schedule::VERSION).not_to be nil
  end
  
  it "Hutch config" do
    expect(Hutch::Config.default_config.class).to eq Hash
  end
  
  describe 'running' do
    before(:each) do
      Hutch::Config.set(:mq_vhost, 'ajd')
    end
    
    after(:each) do
      Hutch::Schedule::DELAY_QUEUES.each do |suffix|
        queue_name = Hutch::Schedule.delay_queue_name(suffix)
        Hutch.broker.channel.queue_delete(queue_name)
      end
      Hutch::Schedule.disconnect
    end
    
    it 'check delay queue is set' do
      Hutch::Schedule.connect
      expect(Hutch.connected?).to be true
      Hutch::Schedule::DELAY_QUEUES.each do |suffix|
        queue_name = Hutch::Schedule.delay_queue_name(suffix)
        expect(Hutch.broker.channel.connection.queue_exists?(queue_name)).to be true
      end
    end
    
    # 用于手动测试 woker
    it 'process', skip: false do
      Hutch::Schedule.connect
      @worker = Hutch::Worker.new(Hutch.broker, Hutch.consumers, Hutch::Config.setup_procs)
      @worker.run
      10.times do
        LoadWork.enqueue(b: 1)
        LoadWork2.enqueue(b: 1)
      end
    end
  end
end
