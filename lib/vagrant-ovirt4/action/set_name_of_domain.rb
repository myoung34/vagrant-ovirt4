module VagrantPlugins
  module OVirtProvider
    module Action

      class SetNameOfDomain
        @@MAX_NAME_LENGTH = 64
        def initialize(app, env)
          @app = app
        end

        def call(env)
          dir_name = env[:root_path].basename.to_s.dup.gsub(/[^-a-z0-9_]/i, "")
          timestamp = "_#{Time.now.to_f}"
          max_dir_name_length = dir_name.length-[(dir_name + timestamp).length-(@@MAX_NAME_LENGTH-1), 0].max
          env[:domain_name] = dir_name[0..max_dir_name_length] << timestamp

          @app.call(env)
        end
      end

    end
  end
end

