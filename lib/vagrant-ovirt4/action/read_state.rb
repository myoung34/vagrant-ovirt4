require "log4r"

module VagrantPlugins
  module OVirtProvider
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::read_state")
        end

        def call(env)
          env[:machine_state_id] = read_state(env)
          @app.call(env)
        end

        def read_state(env)
          vms_service = env[:vms_service]
          machine = env[:machine]
          return :not_created if machine.id.nil?

          server = vms_service.vm_service(machine.id)
          begin
            if server.get.nil?
              machine.id = nil
              return :not_created
            end
          rescue 
            machine.id = nil
            return :not_created
          end
          nics_service = server.nics_service
          nics = nics_service.list
          ip_addr = nics.collect { |nic_attachment| env[:connection].follow_link(nic_attachment.reported_devices).collect { |dev| dev.ips.collect { |ip| ip.address if ip.version == 'v4' } unless dev.ips.nil? } }.flatten.reject { |ip| ip.nil? }.first rescue nil
          unless ip_addr.nil?
            env[:ip_address] = ip_addr
            @logger.debug("Got output #{env[:ip_address]}")
          end

          return server.get.status.to_sym
        end
      end
    end
  end
end
