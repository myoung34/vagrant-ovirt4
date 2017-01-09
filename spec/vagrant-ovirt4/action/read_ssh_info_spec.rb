require 'spec_helper'
require "vagrant-ovirt4/action/read_ssh_info"

describe VagrantPlugins::OVirtProvider::Action::ReadSSHInfo do
  let(:app) { lambda { |env| } }
  let(:env) {
     OpenStruct.new({
       vms_service: {},
       machine: OpenStruct.new({}),
     })
  }

  subject(:action) { described_class.new(app, env) }


  it 'calls read ssh info' do
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
      expect(env.machine_ssh_info).to eq(:not_created)
    end

  end

  context 'machine does not exist' do
    before do
      allow(env.machine).to receive(:id).and_return(nil)
    end
  
    it 'continues the middleware chain' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_ssh_info).to eq(:not_created)
    end

  end

  context 'machine exists' do
    before do
      allow(env.machine).to receive(:id).and_return('wat')
      allow(env.machine).to receive(:config).and_return(OpenStruct.new({
        ssh: OpenStruct.new({
          guest_port: 44,
        }),
      }))
      allow(env.vms_service).to receive(:vm_service).and_return({})
      allow(env.vms_service.vm_service).to receive(:get).and_return({})
      allow(env.vms_service.vm_service).to receive(:nics_service).and_return({})
      allow(env.vms_service.vm_service.nics_service).to receive(:list).and_return({})
      allow(env.vms_service.vm_service.get).to receive(:status).and_return('active')
    end
  
    it 'continues the middleware chain' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_ssh_info).to eq({:host=>nil, :port=>44, :username=>nil, :private_key_path=>nil, :forward_agent=>nil, :forward_x11=>nil})
    end

  end
end

