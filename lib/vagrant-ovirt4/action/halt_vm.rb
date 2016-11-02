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

          machine = env[:vms_service].vm_service(env[:machine].id)
          machine.stop rescue nil #todo dont rescue

          @app.call(env)
        end
      end
    end
  end
end
