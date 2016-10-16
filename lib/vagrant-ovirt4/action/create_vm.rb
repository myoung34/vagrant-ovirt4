require 'log4r'
require 'vagrant/util/retryable'

module VagrantPlugins
  module OVirtProvider
    module Action
      class CreateVM
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::create_vm")
          @app = app
          binding.pry
        end

        def call(env)
          binding.pry
          # Get config.
          config = env[:machine].provider_config
          binding.pry

          # Gather some info about domain
          name = env[:domain_name]

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_ovirt4.creating_vm"))
          env[:ui].info(" -- Name:          #{name}")

          # Create oVirt VM.
          attr = {
              :name     => name,
          }

          begin
            server = env[:ovirt_compute].servers.create(attr)
          rescue OVIRT::OvirtException => e
            raise Errors::FogCreateServerError,
              :error_message => e.message
          end

          # Immediately save the ID since it is created at this point.
          env[:machine].id = server.id

          # Wait till all volumes are ready.
          env[:ui].info(I18n.t("vagrant_ovirt4.wait_for_ready_vm"))
          for i in 0..10
            ready = true
            server = env[:ovirt_compute].servers.get(env[:machine].id.to_s)
            server.volumes.each do |volume|
              if volume.status != 'ok'
                ready = false
                break
              end
            end
            break if ready
            sleep 2
          end

          if not ready
            raise Errors::WaitForReadyVmTimeout
          end

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          # Undo the import
          env[:ui].info(I18n.t("vagrant_ovirt4.error_recovering"))
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
