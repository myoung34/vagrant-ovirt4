require 'log4r'
require 'ovirtsdk4'
require 'vagrant-ovirt4/util/connection'

module VagrantPlugins
  module OVirtProvider
    module Action
      class DisconnectOVirt
        include Util::Connection

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::disconnect_ovirt")
          @app = app
        end

        def call(env)

          # Get config options for ovirt provider.
          @logger.info("Disconnecting oVirt connection")
          safe_close_connection_standard!(env)

          @app.call(env)
        end

      end
    end
  end
end