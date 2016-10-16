require 'log4r'
require 'ovirtsdk4'

module VagrantPlugins
  module OVirtProvider
    module Action
      class ConnectOVirt
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::connect_ovirt")
          @app = app
        end

        def call(env)

          # Get config options for ovirt provider.
          config = env[:machine].provider_config

          conn_attr = {}
          conn_attr[:url] = "#{config.url}/api"
          conn_attr[:username] = config.username if config.username
          conn_attr[:password] = config.password if config.password
          conn_attr[:debug] = config.debug if config.debug
          conn_attr[:insecure] = true if config.insecure

          @logger.info("Connecting to oVirt (#{config.url}) ...")
          OVirtProvider.ovirt_connection = OvirtSDK4::Connection.new(conn_attr)          
          OVirtProvider.vms_service = OVirtProvider.ovirt_connection.system_service.vms_service

          @app.call(env)
        end

      end
    end
  end
end

