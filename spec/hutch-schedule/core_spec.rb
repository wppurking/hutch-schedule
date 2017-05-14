require "spec_helper"

RSpec.describe HutchSchedule::Core do
  it "has a version number" do
    expect(HutchSchedule::VERSION).not_to be nil
  end

  it "Hutch config" do
    expect(Hutch::Config.default_config.class).to eq Hash
  end
end
