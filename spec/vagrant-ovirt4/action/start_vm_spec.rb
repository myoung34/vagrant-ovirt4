require 'spec_helper'
require 'vagrant-ovirt4/action/start_vm'
require 'vagrant-ovirt4/config'

describe VagrantPlugins::OVirtProvider::Action::StartVM do
  include_context 'provider:action'

  subject(:action) { described_class.new(app, env) }

  before do
    allow(env[:ui]).to receive(:info)
    allow(env[:machine].config.vm).to receive(:hostname)
    allow(vm_service.get).to receive(:status).and_return('nominal')
    allow(vm_service).to receive(:start)
  end

  def vm_initialization_hash_including_hostname(hostname)
    hash_including(vm: hash_including(initialization: hash_including(host_name: hostname)))
  end

  context 'given a custom hostname' do
    let(:hostname) { 'HOSTNAME' }

    it 'uses that as the hostname for machine initialization' do
      expect(env[:machine].config.vm).to receive(:hostname).and_return(hostname)
      expect(vm_service).to receive(:start).with(vm_initialization_hash_including_hostname(hostname))
      action.call(env)
    end
  end

  context 'given no custom hostname' do
    it 'uses a default value as the hostname for machine initialization' do
      expect(vm_service).to receive(:start).with(vm_initialization_hash_including_hostname('vagrant'))
      action.call(env)
    end
  end

  context 'given a custom run_once setting' do
    [true, false].each do |value|
      it 'uses that setting' do
        env[:machine].provider_config.run_once = value
        expect(vm_service).to receive(:start).with(hash_including(vm: hash_including(run_once: value)))
        action.call(env)
      end
    end
  end

  context 'given no custom run_once setting' do
    it 'defaults to false' do
      expect(vm_service).to receive(:start).with(hash_including(vm: hash_including(run_once: false)))
      action.call(env)
    end
  end
end
