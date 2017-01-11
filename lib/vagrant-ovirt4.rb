require 'pathname'
require 'vagrant-ovirt4/plugin'

module VagrantPlugins
  module OVirtProvider
    lib_path = Pathname.new(File.expand_path("../vagrant-ovirt4", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")
    autoload :Util,   lib_path.join("util")

    @@ovirt_connection = nil
    @@vms_service = nil
    def self.ovirt_connection
      @@ovirt_connection
    end

    def self.ovirt_connection=(conn)
      @@ovirt_connection = conn
    end

    def self.vms_service
      @@vms_service
    end

    def self.vms_service=(conn)
      @@vms_service = conn
    end



    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
