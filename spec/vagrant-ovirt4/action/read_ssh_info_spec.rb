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

    it 'returns nil' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_ssh_info).to be_nil
    end
  end

  context 'machine does not exist' do
    before do
      allow(env.machine).to receive(:id).and_return(nil)
    end

    it 'returns nil' do
      expect(app).to receive(:call).with(env)
      action.call(env)
      expect(env.machine_ssh_info).to be_nil
    end
  end

  context 'machine exists' do
    let(:port)     { 44 }

    before do
      allow(env.machine).to receive(:id).and_return('wat')
      allow(env.machine).to receive(:config).and_return(OpenStruct.new({
        ssh: OpenStruct.new({
          guest_port: port
        })
      }))
      allow(env.vms_service).to receive(:vm_service).and_return({})
      allow(env.vms_service.vm_service).to receive(:get).and_return({})
      allow(env.vms_service.vm_service).to receive(:nics_service).and_return({})
      allow(env.vms_service.vm_service.nics_service).to receive(:list).and_return({})
      allow(env.vms_service.vm_service.get).to receive(:status).and_return('active')
    end

    context 'with no IP addresses defined' do
      it 'returns nil' do
        expect(app).to receive(:call).with(env)
        action.call(env)
        expect(env.machine_ssh_info).to be_nil
      end
    end

    context 'with at least one IP address defined' do
      let(:host) { '10.10.10.10' }

      before do
        allow(action).to receive(:first_active_ipv4_address).and_return(host)
      end

      it 'returns filled-out SSH information' do
        expect(app).to receive(:call).with(env)
        action.call(env)
        expect(env.machine_ssh_info).to eq(host: host, port: port, username: nil, private_key_path: nil, forward_agent: nil, forward_x11: nil)
      end
    end
  end
end
