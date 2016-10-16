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
              b2.use MessageAlreadyUp
              next
            end

            b2.use StartVM
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

      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectOVirt, action_root.join("connect_ovirt")
      autoload :ReadState, action_root.join("read_state")
      autoload :StartVM, action_root.join("start_vm")

    end
  end
end

