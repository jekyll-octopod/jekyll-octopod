require "spec_helper"

describe "Jekyll::Podcasting::VERSION::STRING" do
  it "should be 0.1.0" do
    Jekyll::Podcasting::VERSION::STRING.should == "0.1.0"
  end
end
