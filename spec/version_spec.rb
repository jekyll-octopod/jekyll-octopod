require "spec_helper"

describe "Jekyll::Octopod::VERSION::STRING" do
  it "should be 0.24.0" do
    expect(Jekyll::Octopod::VERSION::STRING).to eq("0.24.0")
  end
end
