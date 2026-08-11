require "spec_helper"

describe "Jekyll::Octopod::VERSION::STRING" do
  it "should be 0.16.1" do
    expect(Jekyll::Octopod::VERSION::STRING).to eq("0.16.1")
  end
end
