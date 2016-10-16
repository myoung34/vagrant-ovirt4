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

          machine = env[:ovirt_compute].servers.get(env[:machine].id.to_s)
          if machine == nil
            raise Errors::NoVMError,
              :vm_name => env[:machine].id.to_s
          end

          # Start VM.
          begin
            machine.start
          rescue OVIRT::OvirtException => e
            raise Errors::StartVMError,
              :error_message => e.message
          end

          @app.call(env)
        end
      end
    end
  end
end
