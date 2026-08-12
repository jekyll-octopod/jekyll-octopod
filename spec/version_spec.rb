require "spec_helper"

describe "Jekyll::Octopod::VERSION::STRING" do
  it "should be 0.18.2" do
    expect(Jekyll::Octopod::VERSION::STRING).to eq("0.18.2")
  end
end
