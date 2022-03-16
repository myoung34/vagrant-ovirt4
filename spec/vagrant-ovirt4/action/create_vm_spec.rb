require 'spec_helper'
require 'vagrant-ovirt4/action/create_vm'
require 'vagrant-ovirt4/config'

describe VagrantPlugins::OVirtProvider::Action::CreateVM do
  include_context 'provider:action'

  let(:vm) { double('vm', id: 'ID') }

  subject(:action) { described_class.new(app, env) }

  before do
    allow(env[:ui]).to receive(:info)
    allow(env[:machine]).to receive(:"id=").with(vm.id)
    allow(vm_service.get).to receive(:status).and_return('down')
  end

  context 'given a custom vmname' do
    let(:vmname) { 'VMNAME' }

    it 'uses that as the name for machine creation' do
      env[:machine].provider_config.vmname = vmname
      expect(env[:vms_service]).to receive(:add).with(hash_including(name: vmname)).and_return(vm)
      action.call(env)
    end
  end

  context 'given no custom vmname' do
    context 'given a custom hostname' do
      let(:hostname) { 'HOSTNAME' }

      it 'uses that as the name for machine creation' do
        expect(env[:machine].config.vm).to receive(:hostname).and_return(hostname)
        expect(env[:vms_service]).to receive(:add).with(hash_including(name: hostname)).and_return(vm)
        action.call(env)
      end
    end

    context 'given no custom hostname' do
      it 'uses a default name for machine creation' do
        expect(env[:machine].config.vm).to receive(:hostname)
        expect(env[:vms_service]).to receive(:add).with(hash_including(name: 'vagrant')).and_return(vm)
        action.call(env)
      end
    end
  end
end
