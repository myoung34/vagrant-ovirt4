require 'log4r'
require 'vagrant/util/scoped_hash_override'

module VagrantPlugins
  module OVirtProvider
    module Action
      # Resize the disk if necessary, before VM is running.
      class ResizeDisk
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt::action::resize_disk")
          @app = app
        end

        def call(env)
          # Is it necessary to resize the disk?
          config = env[:machine].provider_config
          if config.disk_size.nil?
            # Nothing to do
            @app.call(env)
            return
          end

          # Get machine first.
          begin
            machine = OVirtProvider::Util::Collection.find_matching(
              env[:ovirt_compute].servers.all, env[:machine].id.to_s)
          rescue => e
            raise Errors::NoVMError,
              :vm_name => env[:machine].id.to_s
          end

          # Extend disk size if necessary
          begin
            machine.update_volume(
              :id      => machine.volumes.first.id,
              :size    => config.disk_size*1024*1024*1024,
            )
          rescue => e
            raise Errors::UpdateVolumeError,
              :error_message => e.message
          end

          # Wait till all volumes are ready.
          env[:ui].info(I18n.t("vagrant_ovirt4.wait_for_ready_volume"))
          for i in 0..10
            ready = true
            machine = env[:ovirt_compute].servers.get(env[:machine].id.to_s)
            machine.volumes.each do |volume|
              if volume.status != 'ok'
                ready = false
                break
              end
            end
            break if ready
            sleep 2
          end

          if not ready
            raise Errors::WaitForReadyResizedVolumeTimeout
          end

          @app.call(env)
        end

      end
    end
  end
end

