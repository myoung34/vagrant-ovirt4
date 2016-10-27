require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action

      # Just start the VM.
      class StartVM

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

          # Start VM.
          machine.start

          @app.call(env)
        end
      end
    end
  end
end
