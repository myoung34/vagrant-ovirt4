require 'log4r'
require 'vagrant-ovirt4/errors'
require 'vagrant-ovirt4/util/machine_names'
require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module OVirtProvider
    module Action

      # Just start the VM.
      class StartVM
        include Util::MachineNames
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::start_vm")
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config

          env[:ui].info(I18n.t("vagrant_ovirt4.starting_vm"))

          machine = env[:vms_service].vm_service(env[:machine].id)
          if machine.get.status == nil
            raise Errors::NoVMError,
              :vm_name => env[:machine].id.to_s
          end

          # FIX MULTIPLE NETWORK INTERFACES
          hostname = machine_hostname(env[:machine])

          initialization = {
            host_name: hostname,
            nic_configurations: [],
            custom_script: config.cloud_init,
          }

          configured_ifaces_options = []
          env[:machine].config.vm.networks.each do |network|
            type, options = network
            next unless type == :private_network

            configured_ifaces_options << scoped_hash_override(options, :ovirt)
          end

          (0...configured_ifaces_options.length()).each do |iface_index|
            iface_options = configured_ifaces_options[iface_index]

            if iface_options[:interface_name] != nil then
              iface_name = iface_options[:interface_name]
            else
              iface_name = "eth#{iface_index}"
            end

            if iface_options[:ip] then
              nic_configuration = {
                name: iface_name,
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
                name: iface_name,
                on_boot: true,
                boot_protocol: OvirtSDK4::BootProtocol::DHCP,
              }
            end

            initialization[:nic_configurations] << nic_configuration
            initialization[:dns_servers] = iface_options[:dns_servers] unless iface_options[:dns_servers].nil?
            initialization[:dns_search] = iface_options[:dns_search] unless iface_options[:dns_search].nil?
          end
          # END FIX MULTIPLE NETWORK INTERFACES

          vm_configuration = {
            initialization: initialization,
            placement_policy: {},
          }

          vm_configuration[:placement_policy][:hosts] = [{ :name => config.placement_host }] unless config.placement_host.nil?
          vm_configuration[:placement_policy][:affinity] = config.affinity unless config.affinity.nil?

          vm_configuration.delete(:placement_policy) if vm_configuration[:placement_policy].empty?
          vm_configuration.delete(:nic_configurations) if vm_configuration[:nic_configurations].nil? or vm_configuration[:nic_configurations].empty?

          begin
            machine.start(
              use_cloud_init: true,
              vm: vm_configuration
            )
          rescue OvirtSDK4::Error => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            retry if e.message =~ /Please try again/

            if e.message !~ /VM is running/
              if config.debug
                raise e
              else
                raise Errors::StartVMError,
                  :error_message => fault_message
              end
            end

          end

          @app.call(env)
        end
      end
    end
  end
end
