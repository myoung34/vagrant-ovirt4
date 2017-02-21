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
            next unless [:private_network].include? type

            iface_options = scoped_hash_override(options, :ovirt)
          end

          iface_options = env[:iface_options] unless env[:iface_options].nil? #override settings if set during 'create'

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
                netmask: iface_options[:netmask],
              }
            }
          else
            nic_configuration = {
              name: 'eth0',
              on_boot: true,
              boot_protocol: OvirtSDK4::BootProtocol::DHCP,
            }
          end

          config = env[:machine].provider_config

          vm_configuration = {
            initialization: {
              host_name: hostname,
              nic_configurations: [nic_configuration],
              custom_script: config.cloud_init,
            },
            placement_policy: {},
          }

          vm_configuration[:placement_policy][:hosts] = [{ :name => config.placement_host }] unless config.placement_host.nil?
          vm_configuration[:placement_policy][:affinity] = config.affinity unless config.affinity.nil?
          vm_configuration.delete(:placement_policy) if vm_configuration[:placement_policy].empty?

          vm_configuration[:initialization][:dns_servers] = iface_options[:dns_servers] unless iface_options[:dns_servers].nil?
          vm_configuration[:initialization][:dns_search] = iface_options[:dns_search] unless iface_options[:dns_search].nil?
          
          begin
            machine.start(
              use_cloud_init: true,
              vm: vm_configuration
            )
          rescue OvirtSDK4::Error => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            raise Errors::StartVMError,
              :error_message => fault_message

          end

          @app.call(env)
        end
      end
    end
  end
end
