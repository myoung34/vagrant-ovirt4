require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class SnapshotSave
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::snapshot_save")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.snapshot_save"))
          
          snapshots_service = env[:vms_service].vm_service(env[:machine].id).snapshots_service
          
          snapshots_service.add(
            OvirtSDK4::Snapshot.new(
              description: env[:snapshot_name]
            )
          )

          @app.call(env)
        end
      end
    end
  end
end
