require "spec_helper"

describe "Jekyll::Octopod::VERSION::STRING" do
  it "should be 0.2.0" do
    Jekyll::Octopod::VERSION::STRING.should == "0.2.0"
  end
end
