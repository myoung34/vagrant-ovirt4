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
          conn_attr[:url] = "#{config.url}"
          conn_attr[:username] = config.username if config.username
          conn_attr[:password] = config.password if config.password
          conn_attr[:debug] = config.debug if config.debug
          conn_attr[:insecure] = true if config.insecure
          conn_attr[:headers] = {'Filter' => true} if config.filtered_api
          conn_attr[:timeout] = config.timeout unless config.timeout.nil?
          conn_attr[:connect_timeout] = config.connect_timeout unless config.connect_timeout.nil?

          @logger.info("Connecting to oVirt (#{config.url}) ...")
          ovirt_connection = OvirtSDK4::Connection.new(conn_attr)
          vms_service = ovirt_connection.system_service.vms_service

          # XXX: Continue setting deprecated global properties. Use of the
          # related values from env should be preferred.
          OVirtProvider.ovirt_connection = ovirt_connection
          OVirtProvider.vms_service = vms_service

          begin
            ovirt_connection.test(true, 30)
          rescue => error
            raise Errors::ServiceConnectionError,
              :error_message => error.message
          else
            env[:connection] = ovirt_connection
            env[:vms_service] = vms_service
            @app.call(env)
          end
        end

      end
    end
  end
end

