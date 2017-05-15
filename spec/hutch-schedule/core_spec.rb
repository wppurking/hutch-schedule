require "spec_helper"

RSpec.describe Hutch::Schedule::Core do
  it "has a version number" do
    expect(Hutch::Schedule::VERSION).not_to be nil
  end

  it "Hutch config" do
    expect(Hutch::Config.default_config.class).to eq Hash
  end

end
