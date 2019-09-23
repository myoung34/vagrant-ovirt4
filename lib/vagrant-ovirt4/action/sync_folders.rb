require "log4r"
require "vagrant/util/subprocess"

module VagrantPlugins
  module OVirtProvider
    module Action
      class SyncFolders
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_ovirt::action::sync_folders")
        end

        def call(env)
          @app.call(env)

          ssh_info = env[:machine].ssh_info

          env[:machine].config.vm.synced_folders.each do |id, data|
            next if data[:disabled]
            hostpath  = File.expand_path(data[:hostpath], env[:root_path])
            guestpath = data[:guestpath]
            if env[:machine].config.vm.guest == :windows
              guestpath = guestpath.gsub(/^(\/)/, "/cygdrive/c/")
            end

            # Make sure there is a trailing slash on the host path to avoid creating an additional directory with rsync
            hostpath = "#{hostpath}/" if hostpath !~ /\/$/

            # on windows rsync.exe requires cygdrive-style paths.
            # assumes: /c/...
            # Should be msysgit and cygwin compatible if /etc/fstab in cygwin contains:
            #    none / cygdrive binary,posix=0,user 0 0
            if Vagrant::Util::Platform.windows?
              hostpath = hostpath.gsub(/^(\w):/) { "/#{$1}" }
            end

            env[:ui].info(I18n.t("vagrant_ovirt4.rsync_folder", :hostpath => hostpath, :guestpath => guestpath))

            # Create the guest path
            env[:machine].communicate.sudo("mkdir -p '#{guestpath}'")
            env[:machine].communicate.sudo("chown #{ssh_info[:username]} '#{guestpath}'")

            # Rsync over to the guest path using the SSH info
            command = [
              "rsync", 
              "--verbose", 
              "--archive", 
              "-z", 
              "--owner", 
              "--perms",
              "--exclude", 
              ".vagrant/",
              "-e", 
              "ssh -p #{ssh_info[:port]} -o StrictHostKeyChecking=no -i '#{ssh_info[:private_key_path][0]}'",
              hostpath,
              "#{ssh_info[:username]}@#{ssh_info[:host]}:#{guestpath}"
            ]

            r = Vagrant::Util::Subprocess.execute(*command)
            if r.exit_code != 0
              raise Errors::RsyncError,
                :guestpath => guestpath,
                :hostpath => hostpath,
                :stderr => r.stderr
            end
          end
        end
      end
    end
  end
end

