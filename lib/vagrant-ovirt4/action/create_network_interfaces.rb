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

          iface_options = nil
          env[:machine].config.vm.networks.each do |config|
            type, options = config
            # We support private networks only. They mean both the same right now.
            next unless [:private_network].include? type

            iface_options = scoped_hash_override(options, :ovirt)
          end

          begin
            nics_service = env[:vms_service].vm_service(env[:machine].id).nics_service
            if iface_options.nil?
              # throw an error if they didn't provide any sort of information on interfaces _and_ the VM has none
              raise Errors::NoNetworkError if nics_service.list.count == 0
            else
              # provided a network block of some sort. Search oVirt for the corresponding network_profile_ids
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
              # error if they provided a 'network name' but it could not be located in the previous search
              raise Errors::NetworkNotFoundError, :network_name => iface_options[:network_name] if network_profile_id.nil? and !iface_options[:network_name].nil?
              # we would continue here if they provided network information but not a network name, meaning to use DHCP
              iface_options.delete(:ip) rescue nil
              env[:iface_options] = iface_options

              # quick and dirty way to look for a 'nic#' that is not already attached to the machine
              iface = (("nic1".."nic8").flat_map { |x| x } - env[:vms_service].vm_service(env[:machine].id).nics_service.list.map(&:name)).first rescue "vagrant_nic1"
              @logger.info("Creating network interface #{iface}")
              nics_service.add(
                OvirtSDK4::Nic.new(
                  name: iface,
                  vnic_profile: {
                    id: network_profile_id
                  }
                )
              )
            end
          rescue => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            raise Errors::AddInterfaceError,
              :error_message => fault_message
          end

          # Continue the middleware chain.
          @app.call(env)

        end
      end
    end
  end
end

