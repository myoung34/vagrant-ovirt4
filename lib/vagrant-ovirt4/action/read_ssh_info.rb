require "log4r"

module VagrantPlugins
  module OVirtProvider
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        # This method powers OVirtProvider::Provider#ssh_info.  It returns a
        # hash of SSH connection information if and only if at least one IPv4
        # address associated with the machine in question could be retrieved
        # from the oVirt API.  Otherwise, it returns nil.
        def read_ssh_info(env)
          vms_service, machine = env[:vms_service], env[:machine]
          return nil if machine.id.nil?

          # Find the machine
          server = vms_service.vm_service(machine.id)
          begin
            if server.get.nil?
              machine.id = nil
              return nil
            end
          rescue Exception => e
            machine.id = nil
            return nil
          end

          nics_service = server.nics_service
          nics = nics_service.list
          ip_addr = first_active_ipv4_address(env, nics)

          return nil if ip_addr.nil?

          # Return the info
          # TODO: Some info should be configurable in Vagrantfile
          return {
            :host             => ip_addr,
            :port             => machine.config.ssh.guest_port,
            :username         => machine.config.ssh.username,
            :private_key_path => machine.config.ssh.private_key_path,
            :forward_agent    => machine.config.ssh.forward_agent,
            :forward_x11      => machine.config.ssh.forward_x11,
          }

        end

      private

        def first_active_ipv4_address(env, nics)
          nics.collect { |nic_attachment| env[:connection].follow_link(nic_attachment.reported_devices).collect { |dev| dev.ips.collect { |ip| ip.address if ip.version == 'v4' } unless dev.ips.nil? } }.flatten.reject { |ip| ip.nil? }.first
        rescue
          # for backwards compatibility with ovirt 4.3
          nics.collect { |nic_attachment| env[:connection].follow_link(nic_attachment).reported_devices.collect { |dev| dev.ips.collect { |ip| ip.address if ip.version == 'v4' } unless dev.ips.nil? } }.flatten.reject { |ip| ip.nil? }.first rescue nil
        end
      end
    end
  end
end
