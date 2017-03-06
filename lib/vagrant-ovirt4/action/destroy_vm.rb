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

          vm_service = env[:vms_service].vm_service(env[:machine].id)
          begin
            vm_service.remove
          rescue OvirtSDK4::Error => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            retry if e.message =~ /Please try again/

            if config.debug
              raise e
            else
              raise Errors::RemoveVMError,
                :error_message => fault_message
            end
          end

          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
