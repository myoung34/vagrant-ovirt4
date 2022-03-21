[OvirtSDK4::Connection#initialize]: https://rubydoc.info/gems/ovirt-engine-sdk/OvirtSDK4%2FConnection:initialize

# Vagrant oVirt v4 Provider

This is a [Vagrant](http://www.vagrantup.com) 1.1+ plugin that adds an
[oVirt v4](http://ovirt.org) and
allowing Vagrant to control and provision machines in oVirt.

## Installation

```
$ vagrant plugin install vagrant-ovirt4
$ vagrant up --provider=ovirt4
```

## Usage

### Prerequisites

#### Configuration

1. [ovirt-guest-agent](https://github.com/oVirt/ovirt-guest-agent)
1. [cloud-init](https://cloudinit.readthedocs.io/en/latest/)
1. User 'vagrant'
  1. password 'vagrant'
  1. Public key [from here](https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub)
  1. add to group with sudo no password
1. set `!requiretty` in sudoers
1. firewall off and ssh enabled

#### Example creation steps

1. Create a base template
  1. Centos Example
    1. Spin up a virtual machine using the Centos 7 Generic Cloud Image from the ovirt Glance provider
    1. Once it is up and running, run [the example script](tools/prepare_redhat_for_box.sh) from inside the VM
    1. Power down the virtual machine
    1. Remove all Network Interfaces from the VM (so that the template does not have it)
    1. Right click the virtual machine and click 'Make Template'

### Supported Commands (tested)

1. `vagrant up`
1. `vagrant destroy`
1. `vagrant ssh [-c '#command']`
1. `vagrant ssh-config`
1. `vagrant halt`
1. `vagrant reload`
1. `vagrant status`
1. `vagrant suspend`
1. `vagrant resume`
1. `vagrant snapshot list`
1. `vagrant snapshot delete [id]`
1. `vagrant snapshot save [description]`

### Configuration example

```
Vagrant.configure("2") do |config|
  config.vm.box = 'ovirt4'
  config.vm.hostname = "foo"
  config.vm.box_url = 'https://github.com/myoung34/vagrant-ovirt4/blob/master/example_box/dummy.box?raw=true'

  config.vm.network :private_network,
    :ovirt__network_name => 'ovirtmgmt' #DHCP
    # Static configuration
    #:ovirt__ip => '192.168.2.198', :ovirt__network_name => 'ovirtmgmt', :ovirt__gateway => '192.168.2.125', :ovirt__netmask => '255.255.0.0', :ovirt__dns_servers => '192.168.2.1', :ovirt__dns_search => 'test.local'
    # Static configuration with biosdevname. Guest OS assigns interface names (ens3, em1 or something else). ovirt__interface_name has to match that name.
    #:ovirt__ip => '192.168.2.198', :ovirt__network_name => 'ovirtmgmt', :ovirt__gateway => '192.168.2.125', :ovirt__netmask => '255.255.0.0', :ovirt__dns_servers => '192.168.2.1', :ovirt__dns_search => 'test.local', :ovirt__interface_name => 'ens3'

#  configure additional interface
#  config.vm.network :private_network,
#    :ovirt__ip => '192.168.2.199', :ovirt__network_name => 'ovirtmgmt', :ovirt__netmask => '255.255.0.0', :ovirt__interface_name => 'ens4'

  config.vm.provider :ovirt4 do |ovirt|
    ovirt.url = 'https://server/ovirt-engine/api'
    ovirt.username = "admin@internal"
    ovirt.password = "password"
    ovirt.insecure = true
    ovirt.debug = true
    ovirt.timeout = 120 # seconds
    ovirt.connect_timeout = 30 # seconds
    ovirt.filtered_api = true #see http://www.ovirt.org/develop/release-management/features/infra/user-portal-permissions/
    ovirt.cluster = 'Default'
    ovirt.vmname = 'my-vm'
    ovirt.run_once = false
    ovirt.template = 'Vagrant-Centos7-test'
    ovirt.console = 'vnc'
    ovirt.disk_size = '15 GiB' # only growing is supported. works the same way as below memory settings
    ovirt.memory_size = '1 GiB' #see https://github.com/dominikh/filesize for usage
    ovirt.memory_guaranteed = '256 MiB' #see https://github.com/dominikh/filesize for usage
    ovirt.cpu_cores = 2
    ovirt.cpu_sockets = 2
    ovirt.cpu_threads = 2
    ovirt.bios_serial = aaabbbb-ccc-dddd
    ovirt.optimized_for = 'server'
    ovirt.cloud_init =<<EOF
write_files:
  - content: |
      Hello, world!
    path: /tmp/greeting.txt
    permissions: '0644'
EOF

    # additional disks
    ovirt.storage :file, size: "8 GiB", type: 'qcow2', storage_domain: "mystoragedomain"
  end
end
```

### Configuration options

1. Vagrant specific
  1. `config.vm.hostname` => Sets the hostname of the VM. Optional. String.
     Default is `"vagrant"`.
    a. Is the 'hostname' of the VM configured by `cloud-init`
  1. `config.vm.network` => Sets the network information of the VM.
    a. Note: `:ip` => is ignored, but `:ovirt__ip` is used and merged with `:ip`
1. Provider specific
  1. `config.vm.network` => Sets the network information of the VM.
    a. Note: Only `:private_network` is currently supported.
    a. If `:ovirt__ip` is provided, then the network type is assumed 'STATIC' and `gateway` is also used.
  1. `url` =>  The URL for the API. Required. String. No default value.
  1. `username` => The username for the API. Required. String. No default value.
  1. `password` => The password for the API. Required. String. No default value.
  1. `insecure` => Allow connecting to SSL sites without certificates. Optional. Bool. Default is `false`
  1. `debug` => Turn on additional log statements. Optional. Bool. Default is
     `true` if Vagrant's logging verbosity is set to `info` or above
     (`VAGRANT_LOG={info,debug,...}`); otherwise, the default is `false`.
  1. `timeout` => Per [the oVirt SDK docs][OvirtSDK4::Connection#initialize],
     "The maximun (_sic_) total time to wait for the response, in seconds. A value of
     zero (the default) means wait for ever." Optional. Integer. Uses the
     `OvirtSDK4::Connection` default if omitted; as of the time of writing,
     this is `0` (i.e. wait forever).
  1. `connect_timeout` => Per [the oVirt SDK docs][OvirtSDK4::Connection#initialize],
     "The maximun (_sic_) time to wait for connection establishment, in
     seconds." Optional. Integer. Uses the `OvirtSDK4::Connection` default if
     omitted; as of the time of writing, this is `300`.
  1. `vmname` => Sets the name of the VM. Optional. String. Default is
     `config.vm.hostname`, if defined, otherwise `"vagrant"`.
    a. Is the 'name' in the Virtual Machine tab of the UI
  1. `run_once` => Launch VM in run-once mode. Optional. Default is `false`.
  1. `template` => The name of the template to use for creation. Required. String. No Default value.
  1. `cluster` => The name of the ovirt cluster to create within. Required. String. No Default value.
  1. `console` => The type of remote viewing protocol to use. Required. String. No Default value.
  1. `memory_size` => The physical size of the memory for the VM (in MB). Defaults to `256`
  1. `memory_guaranteed` => The guaranteed size of the memory for the VM (in MB). Note: cannot be larger than `memory_size`. Defaults to `memory_size`
  1. `cpu_cores` => The number of CPU cores. Defaults to `1`
  1. `cpu_sockets` => The number of CPU cores. Defaults to `1`
  1. `cpu_threads` => The number of CPU threads. Defaults to `1`
  1. `cloud_init` => The cloud-init data to pass. Must be properly formatted as yaml. [Docs here](http://cloudinit.readthedocs.io/en/latest/topics/examples.html)
  1. `affinity` =>  The affinity to use. [See this for possible uses](http://www.rubydoc.info/gems/ovirt-engine-sdk/OvirtSDK4/VmAffinity). Optional. Invalid will cause a `RuntimeError`
  1. `placement_host` => The host to start the VM on. Optional.
  1. `bios_serial` => The BIOS serial number to assign. Optional.
  1. `optimized_for` => The "optimized for" setting. Can be one of 'Desktop' or 'Server' (case insensitive). Optional.
  1. `storage` => adds a new storage disk to the VM
    a. `size`: the size of the disk
    a. `type`: the type of disk. It can be either `qcow2` or `raw`
    a. `storage_domain`: the storage domain where the disk should be created


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Some pointers:

* To install the requirements when developing:
    * `bundle install`
* To run the test suite:
    * `bundle exec rspec spec/`
