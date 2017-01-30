module VagrantPlugins
  module OVirtProvider
    module Cap
      module SnapshotList
        def self.snapshot_list(machine)
          env = machine.action(:snapshot_list, lock: false)
          env[:machine_snapshot_list]
        end
      end
    end
  end
end
