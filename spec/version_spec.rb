require "spec_helper"

describe "Jekyll::Octopod::VERSION::STRING" do
  it "should be 0.8.9" do
    Jekyll::Octopod::VERSION::STRING.should == "0.8.9"
  end
end
