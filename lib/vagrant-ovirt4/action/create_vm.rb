require 'log4r'
require 'vagrant/util/retryable'

module VagrantPlugins
  module OVirtProvider
    module Action
      class CreateVM
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_ovirt4::action::create_vm")
          @app = app
        end

        def call(env)
          # Get config.
          config = env[:machine].provider_config

          hostname = env[:machine].config.vm.hostname
          hostname = 'vagrant' if hostname.nil?

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_ovirt4.creating_vm"))
          env[:ui].info(" -- Name:          #{hostname}")
          env[:ui].info(" -- Cluster:       #{config.cluster}")
          env[:ui].info(" -- Template:      #{config.template}")
          env[:ui].info(" -- Console Type:  #{config.console}")
          env[:ui].info(" -- BIOS Serial:   #{config.bios_serial}")
          env[:ui].info(" -- Optimized For: #{config.optimized_for}")
          env[:ui].info(" -- Description:   #{config.description}")
          env[:ui].info(" -- Comment:       #{config.comment}")
          env[:ui].info(" -- Memory:        ")
          env[:ui].info(" ---- Memory:      #{Filesize.from("#{config.memory_size} B").to_f('MB').to_i} MB")
          env[:ui].info(" ---- Maximum:     #{Filesize.from("#{config.memory_maximum} B").to_f('MB').to_i} MB")
          env[:ui].info(" ---- Guaranteed:  #{Filesize.from("#{config.memory_guaranteed} B").to_f('MB').to_i} MB")
          env[:ui].info(" -- Cpu:           ")
          env[:ui].info(" ---- Cores:       #{config.cpu_cores}")
          env[:ui].info(" ---- Sockets:     #{config.cpu_sockets}")
          env[:ui].info(" ---- Threads:     #{config.cpu_threads}")
          env[:ui].info(" -- Cloud-Init:    #{!config.cloud_init.nil? }")

          # Create oVirt VM.
          attr = {
              :name     => hostname,
              :description => config.description,
              :comment => config.comment,
              :cpu      => {
                :architecture => 'x86_64',
                :topology => {
                  :cores   => config.cpu_cores,
                  :sockets => config.cpu_sockets,
                  :threads => config.cpu_threads,
                },
              },
              :memory_policy => OvirtSDK4::MemoryPolicy.new(
                ballooning: true,
                guaranteed: config.memory_guaranteed,
                max: config.memory_maximum,
              ),
              :memory   => config.memory_size,
              :cluster  => {
                :name => config.cluster,
              },
              :template => {
                :name => config.template,
              },
              :display  => {
                :type => config.console,
              },
              :type => config.optimized_for,
          }

          begin
            server = env[:vms_service].add(attr) 
          rescue OvirtSDK4::Error => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            retry if e.message =~ /Related operation is currently in progress/

            if config.debug
              raise e
            else
              raise Errors::CreateVMError,
                :error_message => fault_message
            end
          end

          # Immediately save the ID since it is created at this point.
          env[:machine].id = server.id

          # Wait till all volumes are ready.
          env[:ui].info(I18n.t("vagrant_ovirt4.wait_for_ready_vm"))
          for i in 0..300
            disk_ready = true
            vm_service = env[:vms_service].vm_service(env[:machine].id)
            disk_attachments_service = vm_service.disk_attachments_service
            disk_attachments = disk_attachments_service.list
            disk_attachments.each do |disk_attachment|
              disk = env[:connection].follow_link(disk_attachment.disk)
              if disk.status != 'ok'
                disk_ready = false
                break
              end
            end
            ready = (disk_ready and env[:vms_service].vm_service(server.id).get.status.to_sym == :down)
            break if ready
            sleep 2
          end

          if not ready
            raise Errors::WaitForReadyVmTimeout
          end

          begin
            if config.bios_serial
              vm_service = env[:vms_service].vm_service(env[:machine].id)
              vm_service.update(
                serial_number: {
                  policy: OvirtSDK4::SerialNumberPolicy::CUSTOM,
                  value: config.bios_serial,
                }
              )
            end
          rescue OvirtSDK4::Error => e
            fault_message = /Fault detail is \"\[?(.+?)\]?\".*/.match(e.message)[1] rescue e.message
            retry if e.message =~ /Related operation is currently in progress/

            if config.debug
              raise e
            else
              raise Errors::UpdateBiosError,
                :error_message => fault_message
            end
          end


          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          # Undo the import
          env[:ui].info(I18n.t("vagrant_ovirt4.error_recovering"))
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
