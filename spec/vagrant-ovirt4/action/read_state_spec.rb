require 'spec_helper'
require "vagrant-ovirt4/action/read_state"

describe VagrantPlugins::OVirtProvider::Action::ReadState do
  let(:app) { lambda { |env| } }
  let(:env) {
     OpenStruct.new({
       vms_service: {},
       machine: OpenStruct.new({}),
     })
  }

  subject(:action) { described_class.new(app, env) }


  it 'calls read state' do
    expect(action).to receive(:call).with(env)
    action.call(env)
  end
  
  context 'unknown API error' do
    before do
      allow(env.machine).to receive(:id).and_return('wat')
      allow(env.vms_service).to receive(:vm_service).and_return({})
      allow(env.vms_service.vm_service).to receive(:get).and_raise('boom')

    end
  
    it 'continues the middleware chain' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_state_id).to eq(:not_created)
    end

  end

  context 'machine does not exist' do
    before do
      allow(env.machine).to receive(:id).and_return(nil)
    end
  
    it 'continues the middleware chain' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_state_id).to eq(:not_created)
    end

  end

  context 'machine exists' do
    before do
      allow(env.machine).to receive(:id).and_return('wat')
      allow(env.vms_service).to receive(:vm_service).and_return({})
      allow(env.vms_service.vm_service).to receive(:get).and_return({})
      allow(env.vms_service.vm_service).to receive(:nics_service).and_return([])
      allow(env.vms_service.vm_service.get).to receive(:status).and_return('active')
      allow(env.vms_service.vm_service.nics_service).to receive(:list).and_return([])
    end
  
    it 'continues the middleware chain' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_state_id).to eq(:active)
    end

  end
end

