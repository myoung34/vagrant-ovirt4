require 'log4r'
require 'vagrant-ovirt4/util/timer'
require 'vagrant/util/retryable'

module VagrantPlugins
  module OVirtProvider
    module Action

      # Wait till VM is stopped
      class WaitTillDown
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::wait_till_down")
          @app = app
        end

        def call(env)
          vm_service = env[:vms_service].vm_service(env[:machine].id)

          env[:ui].info(I18n.t("vagrant_ovirt4.wait_till_down"))
          for i in 1..300
            ready = true
            begin
              if vm_service.get == nil
                raise NoVMError, :error_message => '', :vm_id => env[:machine].id
              end
            rescue OvirtSDK4::Error => e
              fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
              if config.debug
                raise e
              else
                raise Errors::NoVMError, :error_message => fault_message, :vm_id => env[:machine].id
              end
            end



            if vm_service.get.status.to_sym != :down
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

