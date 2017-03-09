require 'log4r'
require 'vagrant-ovirt4/util/timer'
require 'vagrant/util/retryable'

module VagrantPlugins
  module OVirtProvider
    module Action
      class WaitTilSuspended
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::wait_til_suspended")
          @app = app
        end

        def call(env)
          vm_service = env[:vms_service].vm_service(env[:machine].id)

          env[:ui].info(I18n.t("vagrant_ovirt4.wait_til_suspended"))
          for i in 1..300
            ready = true
            if vm_service.get == nil
              raise NoVMError, :vm_id => env[:machine].id
            end

            if vm_service.get.status.to_sym != :suspended
              ready = false
            end
            break if ready
            sleep 2
          end

          if not ready
            raise Errors::WaitForShutdownVmTimeout
          end

          
          @app.call(env)
        end

      end
    end
  end
end
