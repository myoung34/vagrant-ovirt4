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
    end
  end
end

