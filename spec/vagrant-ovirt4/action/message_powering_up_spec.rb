require 'spec_helper'
require "vagrant-ovirt4/action/message_powering_up"

describe VagrantPlugins::OVirtProvider::Action::MessagePoweringUp do
  let(:app) { lambda { |env| } }
  let(:env) {
     OpenStruct.new({
       vms_service: {},
       machine: OpenStruct.new({}),
     })
  }


  subject(:action) { described_class.new(app, env) }

  it 'calls message powering up' do
    expect(action).to receive(:call).with(env)
    action.call(env)
  end
end 
