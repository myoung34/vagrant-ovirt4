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
          config = env[:machine].provider_config

          env[:ui].info(I18n.t("vagrant_ovirt4.wait_till_down"))
          for i in 1..300
            ready = true
            server = env[:vms_service].list({:search => "id=#{env[:machine].id}"})[0]
            if server == nil
              raise NoVMError, :vm_name => ''
            end

            if env[:machine].state.id != :down
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

