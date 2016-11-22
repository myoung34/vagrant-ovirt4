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
          env[:machine_state_id] = read_state(env[:vms_service], env[:machine])
          @app.call(env)
        end

        # Possible states include (but may not be limited to):
        # :not_created, :up, :down, :saving_state, :suspended
        def read_state(vms_service, machine)
          return :not_created if machine.id.nil?

          # Find the machine
          server = vms_service.vm_service(machine.id)
          begin
            if server.get.nil?
              machine.id = nil
              return :not_created
            end
          rescue OvirtSDK4::Error => e
            if e.message =~ /404/
              machine.id = nil
              return :not_created
            else
              raise e
            end
          end
          return server.get.status.to_sym
        end
      end
    end
  end
end
