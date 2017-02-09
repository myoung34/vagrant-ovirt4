require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class SnapshotDelete
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::snapshot_delete")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.snapshot_delete"))
          
          snapshots_service = env[:vms_service].vm_service(env[:machine].id).snapshots_service
          
          snapshot = snapshots_service.snapshot_service(env[:snapshot_name])

          begin
            raise RemoveActiveSnapshotError, :id => env[:snapshot_name] if snapshot.get.snapshot_type == 'active' 
            snapshot.remove
          rescue OvirtSDK4::Error => e
            fault_detail = /Fault detail is \"\[(.*)\]\".*/.match(e.message)
            error_message = e.message
            error_message = fault_detail[1] unless fault_detail.nil?
            raise Errors::RemoveSnapshotError,
              :id => env[:snapshot_name],
              :error_message => error_message
          end

          @app.call(env)
        end
      end
    end
  end
end
