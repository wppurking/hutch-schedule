require "spec_helper"

# 需要真正的 rabbitmq 启动
RSpec.describe Hutch::Config do
  it '#worker_pool_size' do
    expect(subject.get(:worker_pool_size)).to eq(20)
    expect(subject.is_num(:worker_pool_size)).to be_truthy
  end
  
  it '#poller_interval' do
    expect(subject.get(:poller_interval)).to eq(1)
    expect(subject.is_num(:poller_interval)).to be_truthy
  end
  
  it '#poller_batch_size' do
    expect(subject.get(:poller_batch_size)).to eq(100)
    expect(subject.is_num(:poller_batch_size)).to be_truthy
  end
  
  it '#ratelimit_redis_url' do
    expect(subject.get(:ratelimit_redis_url)).to eq("redis://127.0.0.1:6379/0")
    expect(subject.is_bool(:ratelimit_redis_url)).to be_falsey
    expect(subject.is_num(:ratelimit_redis_url)).to be_falsey
  end
  
  it '#ratelimit_bucket_interval' do
    expect(subject.get(:ratelimit_bucket_interval)).to eq(1)
    expect(subject.is_num(:ratelimit_bucket_interval)).to be_truthy
  end
end
