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
            vm_service = env[:vms_service].vm_service(env[:machine].id.to_s)
          rescue => e
            raise Errors::NoVMError, :vm_id => env[:machine].id
          end

          disk_attachments_service = vm_service.disk_attachments_service
          disk_attachments = disk_attachments_service.list
          disk = disk_attachments.first.disk

          # Extend disk size if necessary
          begin
            disk_attachment_service = disk_attachments_service.attachment_service(disk.id)
            disk_attachment = disk_attachment_service.update(
              OvirtSDK4::DiskAttachment.new(disk: {provisioned_size: config.disk_size})
            )
          rescue => e
            raise Errors::UpdateVolumeError,
              :error_message => e.message
          end

          # Wait until resize operation has finished.
          disks_service = env[:connection].system_service.disks_service
          disk_service = disks_service.disk_service(disk.id)
          env[:ui].info(I18n.t("vagrant_ovirt4.wait_for_ready_volume"))
          ready = false
          for i in 0..120
            disk = disk_service.get
            if disk.status == OvirtSDK4::DiskStatus::OK
              ready = true
              break
            end
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

