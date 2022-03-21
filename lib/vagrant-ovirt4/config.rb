require 'vagrant'
require 'filesize'
require 'ovirtsdk4'

module VagrantPlugins
  module OVirtProvider
    class Config < Vagrant.plugin('2', :config)

      attr_accessor :url
      attr_accessor :username
      attr_accessor :password
      attr_accessor :insecure
      attr_accessor :debug
      attr_accessor :disk_size
      attr_accessor :filtered_api
      attr_accessor :cpu_cores
      attr_accessor :cpu_sockets
      attr_accessor :cpu_threads
      attr_accessor :template
      attr_accessor :memory_size
      attr_accessor :memory_maximum
      attr_accessor :memory_guaranteed
      attr_accessor :cluster
      attr_accessor :console
      attr_accessor :cloud_init
      attr_accessor :affinity
      attr_accessor :placement_host
      attr_accessor :bios_serial
      attr_accessor :optimized_for
      attr_accessor :description
      attr_accessor :comment
      attr_accessor :vmname
      attr_accessor :disks
      attr_accessor :timeout
      attr_accessor :connect_timeout
      attr_accessor :run_once

      def initialize
        @url               = UNSET_VALUE
        @username          = UNSET_VALUE
        @password          = UNSET_VALUE
        @insecure          = UNSET_VALUE
        @debug             = UNSET_VALUE
        @disk_size         = UNSET_VALUE
        @filtered_api      = UNSET_VALUE
        @cpu_cores         = UNSET_VALUE
        @cpu_sockets       = UNSET_VALUE
        @cpu_threads       = UNSET_VALUE
        @template          = UNSET_VALUE
        @memory_size       = UNSET_VALUE
        @memory_maximum    = UNSET_VALUE
        @memory_guaranteed = UNSET_VALUE
        @cluster           = UNSET_VALUE
        @console           = UNSET_VALUE
        @cloud_init        = UNSET_VALUE
        @affinity          = UNSET_VALUE
        @placement_host    = UNSET_VALUE
        @bios_serial       = UNSET_VALUE
        @optimized_for     = UNSET_VALUE
        @description       = UNSET_VALUE
        @comment           = UNSET_VALUE
        @vmname            = UNSET_VALUE
        @timeout           = UNSET_VALUE
        @connect_timeout   = UNSET_VALUE
        @run_once          = UNSET_VALUE
        @disks             = []

      end

      def storage(storage_type, options = {})
        if storage_type == :file
          _handle_disk_storage(options)
        end
      end

      def _handle_disk_storage(options ={})
        options = {
          name: "storage_disk_#{@disks.length + 1}",
          type: 'qcow2',
          size: Filesize.from('8G').to_f('B').to_i,
          bus: 'virtio'
        }.merge(options)

        disk = {
          name: options[:name],
          device: options[:device],
          type: options[:type],
          size: Filesize.from(options[:size]).to_f('B').to_i,
          storage_domain: options[:storage_domain],
          bus: options[:bus]
        }

        @disks << disk  # append
      end

      def finalize!
        @url = nil if @url == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE
        @insecure = false if @insecure == UNSET_VALUE
        @debug = false if @debug == UNSET_VALUE
        @disk_size = nil if @disk_size == UNSET_VALUE
        @filtered_api = false if @filtered_api == UNSET_VALUE
        @cpu_cores = 1 if @cpu_cores == UNSET_VALUE
        @cpu_sockets = 1 if @cpu_sockets == UNSET_VALUE
        @cpu_threads = 1 if @cpu_threads == UNSET_VALUE
        @cluster = nil if @cluster == UNSET_VALUE
        @console = nil if @console == UNSET_VALUE
        @memory_size = '256 MiB' if @memory_size == UNSET_VALUE
        @memory_maximum = @memory_size if @memory_maximum == UNSET_VALUE
        @memory_guaranteed = @memory_size if @memory_guaranteed == UNSET_VALUE
        @template = nil if @template == UNSET_VALUE
        @cloud_init = nil if @cloud_init == UNSET_VALUE
        @affinity = nil if @affinity == UNSET_VALUE
        @placement_host = nil if @placement_host == UNSET_VALUE
        @bios_serial = nil if @bios_serial == UNSET_VALUE
        @optimized_for = nil if @optimized_for == UNSET_VALUE
        @description = '' if @description == UNSET_VALUE
        @comment = '' if @comment == UNSET_VALUE
        @vmname = nil if @vmname == UNSET_VALUE
        @timeout = nil if @timeout == UNSET_VALUE
        @connect_timeout = nil if @connect_timeout == UNSET_VALUE
        @run_once = @run_once == UNSET_VALUE ? false : !!@run_once

        unless optimized_for.nil?
          raise "Invalid 'optimized_for'. Must be one of #{OvirtSDK4::VmType.constants.map { |s| "'#{s.downcase}'" }.join(' ')}" unless OvirtSDK4::VmType.constants.include? optimized_for.upcase.to_sym
        end

        unless affinity.nil?
          raise "Invalid affinity. Must be one of #{OvirtSDK4::VmAffinity.constants.map { |s| "'#{s.downcase}'" }.join(' ')}" unless OvirtSDK4::VmAffinity.constants.include? affinity.upcase.to_sym
        end

        unless disk_size.nil?
          begin
            @disk_size = Filesize.from(@disk_size).to_f('B').to_i
          rescue ArgumentError
            raise "Not able to parse 'disk_size'. Please verify and check again."
          end
        end

        begin
          @memory_size = Filesize.from(@memory_size).to_f('B').to_i
          @memory_maximum = Filesize.from(@memory_maximum).to_f('B').to_i
          @memory_guaranteed = Filesize.from(@memory_guaranteed).to_f('B').to_i
        rescue ArgumentError
          raise "Not able to parse either `memory_size` or `memory_guaranteed`. Please verify and check again."
        end

        unless timeout.nil?
          begin
            @timeout = Integer(@timeout)
            raise ArgumentError if @timeout < 0
          rescue ArgumentError, TypeError
            raise "`timeout` argument #{@timeout.inspect} is not a valid nonnegative integer"
          end
        end

        unless connect_timeout.nil?
          begin
            @connect_timeout = Integer(@connect_timeout)
            raise ArgumentError if @connect_timeout < 0
          rescue ArgumentError, TypeError
            raise "`connect_timeout` argument #{@connect_timeout.inspect} is not a valid nonnegative integer"
          end
        end
      end

    end
  end
end

