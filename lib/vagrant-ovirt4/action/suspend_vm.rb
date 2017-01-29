require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class SuspendVM
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::suspend_vm")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.suspend_vm"))

          machine = env[:vms_service].vm_service(env[:machine].id)
          machine.suspend

          @app.call(env)
        end
      end
    end
  end
end

