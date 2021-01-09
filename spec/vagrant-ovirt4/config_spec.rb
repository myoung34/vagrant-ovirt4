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
    its("filtered_api")      { should == false }
    its("cpu_cores")         { should == 1 }
    its("cpu_sockets")       { should == 1 }
    its("cpu_threads")       { should == 1 }
    its("cluster")           { should be_nil }
    its("console")           { should be_nil }
    its("template")          { should be_nil }
    its("memory_size")       { should == 256000000 }
    its("memory_maximum")    { should == 256000000 }
    its("memory_guaranteed") { should == 256000000 }
    its("cloud_init")        { should be_nil }
    its("affinity")          { should be_nil }
    its("placement_host")    { should be_nil }
    its("bios_serial")       { should be_nil }
    its("optimized_for")     { should be_nil }
    its("description")       { should == '' }
    its("comment")           { should == '' }

  end

  describe "overriding defaults" do
    [:url, :username, :password, :insecure, :debug, :filtered_api, :cpu_cores, :cpu_sockets, :cpu_threads, :cluster, :console, :template, :cloud_init, :placement_host, :bios_serial, :optimized_for, :description, :comment].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end

  describe "overriding memory defaults" do
    [:memory_size, :memory_maximum, :memory_guaranteed].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "512 MiB")
        instance.finalize!
        instance.send(attribute).should == 512000000
      end

      it "should convert the value" do
        instance.send("#{attribute}=".to_sym, "1 GiB")
        instance.finalize!
        instance.send(attribute).should == 1000000000
      end

    end
  end

  describe "overriding affinity defaults" do
    [:affinity].each do |attribute|

      context 'valid value' do
        it "should not default #{attribute} if overridden" do
          instance.send("#{attribute}=".to_sym, "pinned")
          instance.finalize!
          instance.send(attribute).should == "pinned"
        end
      end

      context 'invalid value' do
        it "should error" do
          expect {
            instance.send("#{attribute}=".to_sym, "foo")
            instance.finalize!
          }.to raise_error(RuntimeError)

        end

      end

    end
  end
end
