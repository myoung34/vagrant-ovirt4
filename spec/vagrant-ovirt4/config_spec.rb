require "vagrant-ovirt4/config"
require 'rspec/its'

# remove deprecation warnings
# (until someone decides to update the whole spec file to rspec 3.4)
RSpec.configure do |config|
  # ...
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

describe VagrantPlugins::OVirtProvider::Config do
  let(:instance) { described_class.new }

  # Ensure tests are not affected by AWS credential environment variables
  before :each do
    ENV.stub(:[] => nil)
  end

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("url")               { should be_nil }
    its("username")          { should be_nil }
    its("password")          { should be_nil }
    its("insecure")          { should == false }
    its("debug")             { should == false }
    its("cpu_cores")         { should == 1 }
    its("cpu_sockets")       { should == 1 }
    its("cpu_threads")       { should == 1 }
    its("cluster")           { should be_nil }
    its("console")           { should be_nil }
    its("template")          { should be_nil }
    its("memory_size")       { should == 256 }
    its("memory_guaranteed") { should == 256 }
    its("cloud_init")        { should be_nil }

  end

  describe "overriding defaults" do
    [:url, :username, :password, :insecure, :debug, :cpu_cores, :cpu_sockets, :cpu_threads, :cluster, :console, :template, :cloud_init].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end

  describe "overriding memory defaults" do
    [:memory_size, :memory_guaranteed].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "512 MB")
        instance.finalize!
        instance.send(attribute).should == 512
      end

      it "should convert the value" do
        instance.send("#{attribute}=".to_sym, "1 GB")
        instance.finalize!
        instance.send(attribute).should == 1000
      end

    end
  end

end
