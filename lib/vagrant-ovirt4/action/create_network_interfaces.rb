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

          raise Errors::NoNetworkError if iface_options[:network_name].nil?
          config = env[:machine].provider_config
          @logger.info("Finding network #{iface_options[:network_name]} for given cluster #{config.cluster}")
          clusters_service = env[:connection].system_service.clusters_service
          cluster = clusters_service.list(search: "name=#{config.cluster}").first
          profiles_service = env[:connection].system_service.vnic_profiles_service
          network_profile_ids = profiles_service.list.map do |profile|
            if env[:connection].follow_link(profile.network).data_center.id == cluster.data_center.id and
                 profile.name == iface_options[:network_name]
              profile.id
            end
          end
          network_profile_id = network_profile_ids.compact.first
          raise Errors::NetworkNotFounderror, :network_name => iface_options[:network_name] if network_profile_id.nil?

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

