require "spec_helper"

RSpec.describe Hutch::Threshold do
  it '@rate_limiter is class object instance variable' do
    expect(LoadWork.instance_variable_get(:@rate_limiter).class).to eq(Ratelimit)
    w1 = LoadWork.new
    w2 = LoadWork.new
    expect(w1.class.instance_variable_get(:@rate_limiter)).to eq(w2.class.instance_variable_get(:@rate_limiter))
  end
  
  it 'default threshold interval is 1s' do
    class LoadWork3 < NoThresholdWork
      consume 'load3'
      threshold rate: 3
    end
    
    expect(LoadWork3._interval).to eq 1
  end
  
  it 'default threshold context is default' do
    class LoadWork4 < NoThresholdWork
      consume 'load4'
      threshold -> { { rate: 2 } }
    end
    
    expect(LoadWork4._context).to eq 'default'
    expect(LoadWork4._interval).to eq 1
  end
  
  context 'not config #threshold' do
    it 'no #threshold no @rate_limiter' do
      expect(NoThresholdWork.instance_variable_get(:@rate_limiter)).to be_nil
    end
    
    it '#ratelimit_exceeded? eq false' do
      expect(NoThresholdWork.ratelimit_exceeded?).to be_falsey
    end
    
    it '#ratelimit_add eq nil' do
      expect(NoThresholdWork.ratelimit_add).to be_nil
    end
  end
end
