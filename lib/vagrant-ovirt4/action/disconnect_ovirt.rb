require 'log4r'
require 'ovirtsdk4'

module VagrantPlugins
  module OVirtProvider
    module Action
      class DisconnectOVirt
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::disconnect_ovirt")
          @app = app
        end

        def call(env)

          # Get config options for ovirt provider.
          @logger.info("Disconnecting oVirt connection")
          env[:connection].close()

          @app.call(env)
        end

      end
    end
  end
end