require 'vagrant/action/builder'

module VagrantPlugins
  module OVirtProvider
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to bring the box up from nothing.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :up
              b2.use SyncFolders
              b2.use MessageAlreadyUp
              next
            end

            if env[:machine_state_id] == :saving_state
              b2.use MessageSavingState
              next
            end

            if env[:machine_state_id] == :not_created
              #b2.use SetNameOfDomain
              b2.use CreateVM
              #b2.use ResizeDisk

              #b2.use Provision
              b2.use CreateNetworkInterfaces

              #b2.use SetHostname
            end

            b2.use StartVM
            b2.use WaitTillUp
            b2.use SyncFolders
          end
        end
      end

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConnectOVirt
            b2.use ProvisionerCleanup, :before if defined?(ProvisionerCleanup)
            b2.use HaltVM
            b2.use WaitTillDown
            b2.use DestroyVM
          end
        end
      end


      # This action is called to read the state of the machine. The resulting
      # state is expected to be put into the `:machine_state_id` key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use ReadState
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use ReadSSHInfo
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use MessageNotCreated
              next
            end
            if env[:machine_state_id] != :up
              b2.use MessageNotUp
              next
            end

            raise Errors::NoIPError if env[:ip_address].nil?
            b2.use SSHExec
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use Call, ReadState do |env, b2|
            if env[:machine_state_id] == :not_created
              b2.use MessageNotCreated
              next
            end
            if env[:machine_state_id] != :up
              b2.use MessageNotUp
              next
            end

            raise Errors::NoIPError if env[:ip_address].nil?
            b2.use SSHRun
          end
        end
      end


      def self.action_halt
        with_ovirt do |env, b|
          b.use Call, IsRunning do |env2, b2|
            if env[:machine_state_id] == :powering_up
              b2.use MessagePoweringUp
              next
            end
            if !env2[:result]
              b2.use MessageNotUp
              next
            end
            b2.use HaltVM
            b2.use WaitTillDown
          end
        end
      end

      def self.action_reload
        with_ovirt do |env, b|
          b.use action_halt
          b.use action_up
        end
      end

      def self.action_suspend
        with_ovirt do |env, b|
          b.use Call, IsRunning do |env2, b2|
            if env[:machine_state_id] == :powering_up
              b2.use MessagePoweringUp
              next
            end
            if !env2[:result]
              b2.use MessageNotUp
              next
            end
            b2.use SuspendVM
            b2.use WaitTilSuspended
          end
        end
      end

      def self.action_resume
        with_ovirt do |env, b|
          if env[:machine_state_id] == :saving_state
            b.use MessageSavingState
            next
          end
          if env[:machine_state_id] != :suspended
            b.use MessageNotSuspended
            next
          end
          b.use action_up
        end
      end

      def self.action_snapshot_list
        with_ovirt do |env, b|
          b.use SnapshotList
        end
      end

      def self.action_snapshot_save
        with_ovirt do |env, b|
          b.use SnapshotSave
        end
      end

      def self.action_snapshot_delete
        with_ovirt do |env, b|
          b.use SnapshotDelete
        end
      end

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectOVirt, action_root.join("connect_ovirt")
      autoload :CreateNetworkInterfaces, action_root.join("create_network_interfaces")
      autoload :CreateVM, action_root.join("create_vm")
      autoload :DestroyVM, action_root.join("destroy_vm")
      autoload :HaltVM, action_root.join("halt_vm")
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsRunning, action_root.join("is_running")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :SnapshotDelete, action_root.join("snapshot_delete")
      autoload :SnapshotList, action_root.join("snapshot_list")
      autoload :SnapshotSave, action_root.join("snapshot_save")
      autoload :StartVM, action_root.join("start_vm")
      autoload :SuspendVM, action_root.join("suspend_vm")
      autoload :SyncFolders, action_root.join("sync_folders")
      autoload :WaitTillDown, action_root.join("wait_till_down")
      autoload :WaitTillUp, action_root.join("wait_till_up")
      autoload :WaitTilSuspended, action_root.join("wait_til_suspended")

      autoload :MessageAlreadyUp, action_root.join("message_already_up")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageNotSuspended, action_root.join("message_not_suspended")
      autoload :MessageNotUp, action_root.join("message_not_up")
      autoload :MessagePoweringUp, action_root.join("message_powering_up")
      autoload :MessageSavingState, action_root.join("message_saving_state")

      private
      def self.with_ovirt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOVirt
          b.use Call, ReadState do |env, b2|
            if !env[:machine_state_id] == :not_created
              b2.use MessageNotCreated
              next
            end
            yield env, b2
          end
        end
      end
    end
  end
end
