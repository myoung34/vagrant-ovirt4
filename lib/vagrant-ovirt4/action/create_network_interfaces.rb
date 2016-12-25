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

          # Setup list of interfaces before creating them
          adapters = []

          # First interface is for provisioning, so this slot is not usable.
          # This interface should be available already from template.
          env[:machine].config.vm.networks.each_with_index do |config, index|
            type, options = config
            # We support private and public networks only. They mean both the
            # same right now.
            next unless [:private_network, :public_network].include? type

            # Get options for this interface. Options can be specified in
            # Vagrantfile in short format (:ip => ...), or provider format
            # (:ovirt__network_name => ...).
            options = scoped_hash_override(options, :ovirt)
            adapters[index] = options
          end

          # Create each interface as new domain device
          adapters.each_with_index do |opts, slot_number|
            iface_number = slot_number + 1

            # Get network profile id
            profiles_service = env[:connection].system_service.vnic_profiles_service
            network_profile_id = profiles_service.list.map { |p| p.id if p.name == opts[:network_name] }.first
            raise Errors::NoNetworkError, :network_name => opts[:network_name] if network_profile_id.nil?

            @logger.info("Creating network interface nic#{iface_number}")
            begin
              # create nic
              nics_service = env[:vms_service].vm_service(env[:machine].id).nics_service
              nics_service.add(
                OvirtSDK4::Nic.new(
                  name: "nic#{iface_number}",
                  vnic_profile: {
                    id: network_profile_id
                  }
                )
              )
            rescue => e
              raise Errors::AddInterfaceError,
                :error_message => e.message
            end
          end

          # Continue the middleware chain.
          @app.call(env)

        end

        private

        def find_empty(array, start=0, stop=8)
          for i in start..stop
            return i if !array[i]
          end
          return nil
        end
      end
    end
  end
end

