require "spec_helper"

class LoadWork
  include Hutch::Consumer
  include Hutch::Enqueue

  consume 'load'

  def process(message)
  end
end

RSpec.describe Hutch::Enqueue do
  it 'have enqueue, enqueue_in and enqueue_at method' do
    expect(LoadWork.respond_to?(:enqueue)).to eq true
    expect(LoadWork.respond_to?(:enqueue_in)).to eq true
    expect(LoadWork.respond_to?(:enqueue_at)).to eq true
  end

  let(:msg) { { a: 1 } }

  it "enqueue use Hutch.publish" do
    expect(Hutch).to receive(:publish).with('load', msg).once
    LoadWork.enqueue(a: 1)
  end


  context 'enqueue_xx' do
    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    it 'enqueue_in' do
      expect(Hutch::Schedule).to receive(:publish)
                                   .with('load', msg, { expiration: 10.seconds.in_milliseconds })
      LoadWork.enqueue_in(10.seconds, msg)
    end

    it "enqueue_at" do
      expect(Hutch::Schedule).to receive(:publish)
                                   .with('load', msg, { expiration: 3.minutes.in_milliseconds })
      LoadWork.enqueue_at(3.minutes.since, msg)
    end
  end

end
