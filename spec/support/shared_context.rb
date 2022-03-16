require 'vagrant-ovirt4/config'

shared_context 'provider:action' do
  let(:app) { double('app') }

  let(:env) {
    {
      connection: double('connection',
        system_service: double('system_service', disks_service: double('disks_service'))
      ),
      machine: double('machine',
        provider: double('provider'),
        provider_config: VagrantPlugins::OVirtProvider::Config.new,
        name: 'machname',
        id: 'ID',
        config: double('config',
          vm: double('vm_config',
            networks: [],
          ),
        ),
      ),
      ui: double('ui'),
      vms_service: double('vms_service'),
    }
  }

  let(:vm_service) {
    double('vm_service',
      disk_attachments_service: double('disk_attachments_service', list: []),
      get: double('get'),
    )
  }

  before do
    allow(app).to receive(:call)
    allow(env[:vms_service]).to receive(:vm_service).with(env[:machine].id).and_return(vm_service)
    env[:machine].provider_config.finalize!
  end
end
