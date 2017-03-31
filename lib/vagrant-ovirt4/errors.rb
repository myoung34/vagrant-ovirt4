require 'vagrant'

module VagrantPlugins
  module OVirtProvider
    module Errors
      class VagrantOVirtError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_ovirt4.errors")
      end

      class NoVMError < VagrantOVirtError
        error_key(:no_vm_error)
      end

      class CreateVMError < VagrantOVirtError
        error_key(:create_vm_error)
      end

      class StartVMError < VagrantOVirtError
        error_key(:start_vm_error)
      end

      class WaitForReadyVmTimeout < VagrantOVirtError
        error_key(:wait_for_ready_vm_timeout)
      end

      class AddInterfaceError < VagrantOVirtError
        error_key(:add_interface_error)
      end

      class NoNetworkError < VagrantOVirtError
        error_key(:no_network_error)
      end

      class NetworkNotFoundError < VagrantOVirtError
        error_key(:network_not_found_error)
      end

      class NoIPError < VagrantOVirtError
        error_key(:no_ip_error)
      end

      class RemoveActiveSnapshotError < VagrantOVirtError
        error_key(:remove_active_snapshot_error)
      end

      class RemoveSnapshotError < VagrantOVirtError
        error_key(:remove_snapshot_error)
      end

      class RemoveVMError < VagrantOVirtError
        error_key(:remove_vm_error)
      end

      class UpdateBiosError < VagrantOVirtError
        error_key(:update_bios_error)
      end
    end
  end
end

