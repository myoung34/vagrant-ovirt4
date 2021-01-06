require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class HaltVM
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::halt_vm")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.halt_vm"))

          # Halt via OS capability
          begin
            if env[:machine].guest.capability?(:halt)
              env[:machine].guest.capability(:halt)
              # Give the VM a chance to shutdown gracefully..."
              sleep 10
            end
          rescue
            env[:ui].info("Failed to shutdown guest gracefully.")
          end

          machine = env[:vms_service].vm_service(env[:machine].id)
          machine.stop rescue nil #todo dont rescue

          @app.call(env)
        end
      end
    end
  end
end
