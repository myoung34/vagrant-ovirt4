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
    :ip => '192.168.56.100', :nictype => 'virtio', :netmask => '255.255.255.0', #normal network configuration
    :ovirt__ip => '192.168.2.198', :ovirt__network_name => 'ovirtmgmt', :ovirt__gateway => '192.168.2.125' # oVirt specific information, overwrites previous on oVirt provider

  config.vm.provider :ovirt4 do |ovirt|
    ovirt.url = 'https://server/ovirt-engine/api'
    ovirt.username = "admin@internal"
    ovirt.password = "password"
    ovirt.insecure = true
    ovirt.debug = true
    ovirt.cluster = 'Default'
    ovirt.template = 'Vagrant-Centos7-test'
    ovirt.console = 'vnc'
    ovirt.memory_size = '1 GiB' #see https://github.com/dominikh/filesize for usage
    ovirt.memory_guaranteed = '256 MB' #see https://github.com/dominikh/filesize for usage
    ovirt.cpu_cores = 2
    ovirt.cpu_sockets = 2
    ovirt.cpu_threads = 2
    ovirt.cloud_init =<<EOF
write_files:
  - content: |
      Hello, world!
    path: /tmp/greeting.txt
    permissions: '0644'
EOF

  end
end
```

### Configuration options

1. Vagrant specific
  1. `config.vm.hostname` => Sets the hostname of the VM
    a. Is the 'name' in the Virtual Machine tab of the UI
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
  1. `debug` => Turn on additional log statements. Optional. Bool. Default is `false`.
  1. `datacenter` => The name of the ovirt datacenter to create within. Required. String. No Default value.
    a. Note: (TODO) [Unknown usage](https://github.com/myoung34/vagrant-ovirt4/issues/26)
  1. `template` => The name of the template to use for creation. Required. String. No Default value.
  1. `cluster` => The name of the ovirt cluster to create within. Required. String. No Default value.
  1. `console` => The type of remote viewing protocol to use. Required. String. No Default value.
    a. Note: (TODO) Enforce this to be Spice, VNC, and RDP
  1. `memory_size` => The physical size of the memory for the VM (in MB). Defaults to `256`
  1. `memory_guaranteed` => The guaranteed size of the memory for the VM (in MB). Note: cannot be larger than `memory_size`. Defaults to `memory_size`
  1. `cpu_cores` => The number of CPU cores. Defaults to `1`
  1. `cpu_sockets` => The number of CPU cores. Defaults to `1`
  1. `cpu_threads` => The number of CPU threads. Defaults to `1`
  1. `cloud_init` => The cloud-init data to pass. Must be properly formatted as yaml. [Docs here](http://cloudinit.readthedocs.io/en/latest/topics/examples.html)
  1. `affinity` =>  The affinity to use. [See this for possible uses](http://www.rubydoc.info/gems/ovirt-engine-sdk/OvirtSDK4/VmAffinity). Optional. Invalid will cause a `RuntimeError`
  1. `placement_host` => The host to start the VM on. Optional.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
