module VagrantPlugins
  module OVirtProvider
    module Cap
      module SnapshotSave
        def self.snapshot_save(machine)
          env = machine.action(:snapshot_save, lock: false)
          env[:machine_snapshot_save]
        end
      end
    end
  end
end
