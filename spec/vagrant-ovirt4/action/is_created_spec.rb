require 'spec_helper'
require "vagrant-ovirt4/action/is_created"

describe VagrantPlugins::OVirtProvider::Action::IsCreated do
  let(:app) { lambda { |env| } }
  let(:env) {
     OpenStruct.new({
       vms_service: {},
       machine: OpenStruct.new({}),
     })
  }

  subject(:action) { described_class.new(app, env) }
 
  context 'is created' do
    before do
      allow(env.machine).to receive(:state).and_return({})
      allow(env.machine.state).to receive(:id).and_return('444')
    end

    it 'calls is created' do
      action.call(env)
      expect(env.result).to eq(true)
    end
  end

  context 'is not created' do
    before do
      allow(env.machine).to receive(:state).and_return({})
      allow(env.machine.state).to receive(:id).and_return(:not_created)
    end

    it 'calls is created' do
      action.call(env)
      expect(env.result).to eq(false)
    end

  end

end
