require "spec_helper"
require 'hutch'

RSpec.describe Hutch::Broker do
  before do
    Hutch::Config.initialize(client_logger: Hutch::Logging.logger)
    @config = Hutch::Config.to_hash
  end

  let!(:config) { @config }

  after do
    Hutch::Config.instance_variable_set(:@config, nil)
    Hutch::Config.initialize
  end
  let(:broker) { Hutch::Broker.new(config) }

  describe '#connect' do
    # open_connection!
    # open_channel!
    # declare_exchange!
    # declare_publisher!
    before do
      allow(broker).to receive(:open_connection!)
      allow(broker).to receive(:open_channel!)
      allow(broker).to receive(:declare_exchange!)
      allow(broker).to receive(:declare_publisher!)
      allow(broker).to receive(:disconnect)
    end

    it '初始化 schedule' do
      expect(broker).to receive(:set_up_schedule!)
      p Hutch::Broker.methods
      broker.connect
    end

  end
end
