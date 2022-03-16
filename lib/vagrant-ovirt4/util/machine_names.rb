module VagrantPlugins
  module OVirtProvider
    module Util
      module MachineNames
        DEFAULT_NAME = 'vagrant'.freeze

      module_function

        def machine_hostname(machine)
          machine.config.vm.hostname || DEFAULT_NAME
        end

        def machine_vmname(machine)
          machine.provider_config.vmname || machine_hostname(machine)
        end
      end
    end
  end
end


