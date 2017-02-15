require 'vagrant'

module VagrantPlugins
  module OVirtProvider
    class Config < Vagrant.plugin('2', :config)

      attr_accessor :url
      attr_accessor :username
      attr_accessor :password
      attr_accessor :insecure
      attr_accessor :debug
      attr_accessor :cpu_cores
      attr_accessor :cpu_sockets
      attr_accessor :cpu_threads
      attr_accessor :template
      attr_accessor :memory_size
      attr_accessor :memory_guaranteed
      attr_accessor :cluster
      attr_accessor :console

      def initialize
        @url               = UNSET_VALUE
        @username          = UNSET_VALUE
        @password          = UNSET_VALUE
        @insecure          = UNSET_VALUE
        @debug             = UNSET_VALUE
        @cpu_cores         = UNSET_VALUE
        @cpu_sockets       = UNSET_VALUE
        @cpu_threads       = UNSET_VALUE
        @template          = UNSET_VALUE
        @memory_size       = UNSET_VALUE
        @memory_guaranteed = UNSET_VALUE
        @cluster           = UNSET_VALUE
        @console           = UNSET_VALUE

      end

      def finalize!
        @url = nil if @url == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE
        @insecure = false if @insecure == UNSET_VALUE
        @debug = false if @debug == UNSET_VALUE
        @cpu_cores = 1 if @cpu_cores == UNSET_VALUE
        @cpu_sockets = 1 if @cpu_sockets == UNSET_VALUE
        @cpu_threads = 1 if @cpu_threads == UNSET_VALUE
        @cluster = nil if @cluster == UNSET_VALUE
        @console = nil if @console == UNSET_VALUE
        @memory_size = 256 if @memory_size == UNSET_VALUE
        @memory_guaranteed = @memory_size if @memory_guaranteed == UNSET_VALUE
        @template = nil if @template == UNSET_VALUE

      end

    end
  end
end

