# -*- encoding: utf-8 -*-
require File.expand_path('../lib/vagrant-ovirt4/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marcus Young"]
  gem.email	        = ["myoung34@my.apsu.edu"]
  gem.description   = %q{Vagrant provider for oVirt and RHEV v4}
  gem.summary       = %q{This vagrant plugin provides the ability to create, control, and destroy virtual machines under oVirt/RHEV}
  gem.homepage      = "https://github.com/myoung34/vagrant-ovirt4"
  gem.licenses      = ['MIT']

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vagrant-ovirt4"
  gem.require_paths = ["lib"]
  gem.version       = VagrantPlugins::OVirtProvider::VERSION

  gem.add_runtime_dependency 'ovirt-engine-sdk', '~> 4.0', '>= 4.0.6'

  gem.add_development_dependency 'rake', '~> 0'

  # rspec 3.4 to mock File
  gem.add_development_dependency "rspec", "~> 3.4"
  gem.add_development_dependency 'rspec-its', '~> 0'
end
