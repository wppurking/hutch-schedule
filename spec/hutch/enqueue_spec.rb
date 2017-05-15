require "spec_helper"

class LoadWork
  include Hutch::Consumer
  include Hutch::Enqueue

  def process(message)
  end
end

RSpec.describe Hutch::Enqueue do
  it 'have enqueue, enqueue_in and enqueue_at method' do
    expect(LoadWork.respond_to?(:enqueue)).to eq true
    expect(LoadWork.respond_to?(:enqueue_in)).to eq true
    expect(LoadWork.respond_to?(:enqueue_at)).to eq true
  end

  it "enqueue use Hutch.publish" do
  end

  it "enqueue_at use Hutch::Schedule.publish" do
    expect(Hutch::Config.default_config.class).to eq Hash
  end

end
