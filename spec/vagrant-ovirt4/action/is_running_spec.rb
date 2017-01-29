require 'spec_helper'
require "vagrant-ovirt4/action/is_running"

describe VagrantPlugins::OVirtProvider::Action::IsRunning do
  let(:app) { lambda { |env| } }
  let(:env) {
     OpenStruct.new({
       vms_service: {},
       machine: OpenStruct.new({}),
     })
  }

  subject(:action) { described_class.new(app, env) }
 
  context 'is running' do
    before do
      allow(env.machine).to receive(:state).and_return({})
      allow(env.machine.state).to receive(:id).and_return(:up)
    end

    it 'calls is running' do
      action.call(env)
      expect(env.result).to eq(true)
    end
  end

  context 'is not running' do
    before do
      allow(env.machine).to receive(:state).and_return({})
      allow(env.machine.state).to receive(:id).and_return(:down)
    end

    it 'calls is running' do
      action.call(env)
      expect(env.result).to eq(false)
    end

  end

end
