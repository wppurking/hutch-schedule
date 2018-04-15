require "spec_helper"

class PlanConsume
  include Hutch::Consumer

  def process(m)
    puts m
  end
end

class BowConsume
  include Hutch::Consumer
  include Hutch::Enqueue

  attempts 3
  consume 'bow'

  def process(m)
    puts m
  end
end

class NopConsume
  include Hutch::Consumer
  include Hutch::Enqueue

  consume 'nop'

  def process(m)
    puts m
  end
end


RSpec.describe Hutch::ErrorHandlers::MaxRetry do

  let(:properties) do
    {
      :content_type => "application/json",
      :delivery_mode => 2,
      :priority => 0,
      :message_id => "0eefe322-a952-4bbb-90ff-c2fa46a021cd",
      :timestamp => Time.parse('2017-05-19 13:57:36 +0800')
    }
  end

  let(:headers) {
    {
      "x-death" => [
        {
          "count" => 1,
          "reason" => "expired",
          "queue" => "hutch_schedule_queue",
          "time" => Time.parse('2017-05-19 12:32:26 +0800'),
          "exchange" => "hutch.schedule",
          "routing-keys" => ["hutch.schedule.5s", "bow"],
          "original-expiration" => "2000"
        }
      ]
    }
  }

  let(:m_headers) {
    {
      "x-death" => [
        {
          "count" => 1,
          "reason" => "expired",
          "queue" => "hutch_schedule_queue",
          "time" => Time.parse('2017-05-19 12:32:26 +0800'),
          "exchange" => "hutch.schedule",
          "routing-keys" => ["hutch.schedule.5s", "bow"],
          "original-expiration" => "2000"
        },
        {
          "count" => 2,
          "reason" => "expired",
          "queue" => "hutch_schedule_queue",
          "time" => Time.parse('2017-05-19 12:32:26 +0800'),
          "exchange" => "hutch.schedule",
          "routing-keys" => ["hutch.schedule.5s", "bow"],
          "original-expiration" => "2000"
        }
      ]
    }
  }

  let(:payload) { "{\"a\":1}" }

  let(:ex) {
    RuntimeError.new("[[\"content_type\",\"application/json\"],[\"delivery_mode\",2],[\"priority\",0],[\"message_id\",\"0eefe322-a952-4bbb-90ff-c2fa46a021cd\"],[\"timestamp\",\"2017-05-19T13:57:36.000+08:00\"]]")
  }

  it 'not include Hutch::Enqueue' do
    expect(subject.handle(properties, payload, PlanConsume, ex)).to eq false
  end

  context 'error retry' do
    it 'retry: 1' do
      expect(BowConsume).to receive(:enqueue_in).with(2, MultiJson.decode(payload), { headers: {} }).once
      subject.handle(properties, payload, BowConsume, ex)
    end

    it 'retry: 2' do
      expect(BowConsume).to receive(:enqueue_in).with(3, MultiJson.decode(payload), { headers: headers }).once
      h = headers.clone
      h['x-death'][0]['original-expiration'] = '2000'
      subject.handle(properties.merge(headers: h), payload, BowConsume, ex)
    end

    it 'retry: 3' do
      headers['x-death'][0]['count'] = 2
      expect(BowConsume).to receive(:enqueue_in).with(18, MultiJson.decode(payload), { headers: headers }).once
      subject.handle(properties.merge(headers: headers), payload, BowConsume, ex)
    end

    it 'retry: 4, do not republish' do
      headers['x-death'][0]['count'] = 3
      expect(BowConsume).to receive(:enqueue_in).exactly(0).times
      subject.handle(properties.merge(headers: headers), payload, BowConsume, ex)
    end

    it 'retry sum 3, do not republish' do
      expect(BowConsume).to receive(:enqueue_in).exactly(0).times
      subject.handle(properties.merge(headers: m_headers), payload, BowConsume, ex)
    end

    it 'won`t retry with no attempts params' do
      expect(NopConsume).to receive(:enqueue_in).exactly(0).times
      subject.handle(properties.merge(headers: headers), payload, NopConsume, ex)
    end
  end
end