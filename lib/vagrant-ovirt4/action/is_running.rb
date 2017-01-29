require "log4r"

module VagrantPlugins
  module OVirtProvider
    module Action
      class IsRunning
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::is_created")
        end

        def call(env)
          env[:result] = env[:machine].state.id == :up
          @app.call(env)
        end
      end
    end
  end
end
