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
  let(:props) { { expiration: 10.seconds.in_milliseconds, headers: { :'CC' => ['load'] } } }

  it "enqueue use Hutch.publish" do
    expect(Hutch).to receive(:publish).with('load', msg).once
    LoadWork.enqueue(a: 1)
  end


  context 'enqueue_xx' do
    before { Timecop.freeze(Time.at(1494837368.8773272)) }

    after { Timecop.return }

    Hutch::Schedule::DELAY_QUEUES.each_with_index do |queue, index|
      it "ensure #{queue} - 0.000001 delay" do
        delay_second = queue.to_i
        expect(Hutch::Schedule).to receive(:publish)
                                     .with(Hutch::Schedule.delay_routing_key(queue),
                                           msg, props.merge!(expiration: delay_second.seconds.in_milliseconds))
        # 加非常小的边界值
        LoadWork.enqueue_in(delay_second - 0.000001, msg)
      end

      it "ensure #{queue} + 0.000001 delay" do
        delay_second = queue.to_i
        # 寻找到下一个 queue
        next_queue = Hutch::Schedule::DELAY_QUEUES[[index + 1, Hutch::Schedule::DELAY_QUEUES.size - 1].min]
        next_queue_delay_seconds = next_queue.to_i

        expect(Hutch::Schedule).to receive(:publish)
                                     .with(Hutch::Schedule.delay_routing_key(next_queue),
                                           msg, props.merge!(expiration: next_queue_delay_seconds.seconds.in_milliseconds))
        # 加非常小的边界值
        LoadWork.enqueue_in(delay_second + 0.000001, msg)
      end
    end

    it 'enqueue_in' do
      expect(Hutch::Schedule).to receive(:publish)
                                   .with(Hutch::Schedule.delay_routing_key("10s"),
                                         msg, props.merge!(expiration: 10.seconds.in_milliseconds))
      LoadWork.enqueue_in(10.seconds, msg)
    end

    it 'enqueue_in in_milliseconds' do
      expect(Hutch::Schedule).to receive(:publish)
                                   .with(Hutch::Schedule.delay_routing_key("20s"),
                                         msg, props.merge!(expiration: 20.seconds.in_milliseconds))
      LoadWork.enqueue_in(10.0002102, msg)
    end

    it "enqueue_at" do
      expect(Hutch::Schedule).to receive(:publish)
                                   .with(Hutch::Schedule.delay_routing_key("180s"),
                                         msg, props.merge!(expiration: 3.minutes.in_milliseconds))
      LoadWork.enqueue_at(3.minutes.since, msg)
    end
  end

end
