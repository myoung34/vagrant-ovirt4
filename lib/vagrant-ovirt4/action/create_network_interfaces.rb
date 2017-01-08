require 'log4r'
require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module OVirtProvider
    module Action

      # Create network interfaces for machine, before VM is running.
      class CreateNetworkInterfaces
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::create_network_interfaces")
          @app = app
        end

        def call(env)

          iface = "nic1"
          iface_options = nil
          env[:machine].config.vm.networks.each do |config|
            type, options = config
            # We support private and public networks only. They mean both the
            # same right now.
            next unless [:private_network].include? type

            iface_options = scoped_hash_override(options, :ovirt)
          end

          profiles_service = env[:connection].system_service.vnic_profiles_service
          network_profile_id = profiles_service.list.map { |p| p.id if p.name == iface_options[:network_name] }.first
          raise Errors::NoNetworkError, :network_name => iface_options[:network_name] if network_profile_id.nil?

          @logger.info("Creating network interface #{iface}")
          begin
            nics_service = env[:vms_service].vm_service(env[:machine].id).nics_service
            nics_service.add(
              OvirtSDK4::Nic.new(
                name: iface,
                vnic_profile: {
                  id: network_profile_id
                }
              )
            )
          rescue => e
            raise Errors::AddInterfaceError,
              :error_message => e.message
          end

          # Continue the middleware chain.
          @app.call(env)

        end
      end
    end
  end
end

