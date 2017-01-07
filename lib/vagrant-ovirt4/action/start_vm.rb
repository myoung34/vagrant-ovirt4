require 'log4r'
require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module OVirtProvider
    module Action

      # Just start the VM.
      class StartVM
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::start_vm")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.starting_vm"))

          machine = env[:vms_service].vm_service(env[:machine].id)
          if machine.get.status == nil
            raise Errors::NoVMError,
              :vm_name => env[:machine].id.to_s
          end

          iface_options = nil
          env[:machine].config.vm.networks.each do |config|
            type, options = config
            next unless [:private_network, :public_network].include? type

            iface_options = scoped_hash_override(options, :ovirt)
          end

          my_script = ""
          #runcmd:
          # - [ service, network, restart]
          #"

          hostname = env[:machine].config.vm.hostname
          hostname = 'vagrant' if hostname.nil?

          nic_configuration = nil
          if iface_options[:ip] then
            nic_configuration = {
              name: 'eth0',
              on_boot: true,
              boot_protocol: OvirtSDK4::BootProtocol::STATIC,
              ip: {
                version: OvirtSDK4::IpVersion::V4,
                address: iface_options[:ip],
                gateway: iface_options[:gateway],
              }
            }
          else
            nic_configuration = {
              name: 'eth0',
              on_boot: true,
              boot_protocol: OvirtSDK4::BootProtocol::DYNAMIC,
            }
          end

          vm_configuration = {
            initialization: {
              host_name: hostname,
              nic_configurations: [nic_configuration],
              custom_script: my_script,
            }
          }
          
          machine.start(
            use_cloud_init: true,
            vm: vm_configuration
          )

          @app.call(env)
        end
      end
    end
  end
end
