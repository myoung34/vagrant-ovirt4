# vim: ai ts=2 sts=2 et sw=2 ft=ruby
module VagrantPlugins
  module OVirtProvider
    module Cap
      module NicMacAddresses
        def self.nic_mac_addresses(machine)
          ovirt = OVirtProvider.ovirt_connection
          interfaces = ovirt.list_vm_interfaces(machine.id.to_s)
          Hash[interfaces.map{ |i| [i[:name], i[:mac]] }]
        end
      end
    end
  end
end

