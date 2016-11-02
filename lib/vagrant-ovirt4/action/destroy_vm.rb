require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class DestroyVM
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::destroy_vm")
          @app = app
        end

        def call(env)
          # Destroy the server, remove the tracking ID
          env[:ui].info(I18n.t("vagrant_ovirt4.destroy_vm"))

          machine = env[:vms_service].vm_service(env[:machine].id)
          vm_service = env[:vms_service].vm_service(env[:machine].id)
          vm_service.remove
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
