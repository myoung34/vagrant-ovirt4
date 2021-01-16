require 'log4r'

module VagrantPlugins
  module OVirtProvider
    module Action
      class SnapshotList
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::snapshot_list")
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_ovirt4.snapshot_list"))

          system_service = env[:connection].system_service

          #Find all storage domains and store the id and name in a
          # hash, so that looking them up later will be faster:
          sds_service = system_service.storage_domains_service
          sds_map = Hash[sds_service.list.map { |sd| [sd.id, sd.name] }]
          
          # For each virtual machine find its snapshots, then for each snapshot
          # find its disks:
          xs = [['id', 'description', 'date']]
          vm_service = env[:vms_service].vm_service(env[:machine].id)
          snaps_service = vm_service.snapshots_service
          snaps_map = Hash[snaps_service.list.map { |snap| [snap.id, { description: snap.description, date: snap.date }] }]
          snaps_map.each do |snap_id, metadata|
            snap_description = metadata[:description]
            snap_date = metadata[:date]
            snap_service = snaps_service.snapshot_service(snap_id)
            disks_service = snap_service.disks_service
            disks_service.list.each do |disk|
              next unless disk.storage_domains.any?
              sd_id = disk.storage_domains.first.id
              sd_name = sds_map[sd_id]
              xs.push([snap_id, snap_description, snap_date.to_s])
            end
          end

          widths = xs.transpose.map { |column_arr| column_arr.map(&:size).max }
          env[:machine_snapshot_list] = 
              xs.map { |row_arr| 
                row_arr.map.with_index { |str, idx| 
                        "%#{widths[idx]}s" % str 
                } .join(" " * 5)
              }

          @app.call(env)
        end
      end
    end
  end
end
