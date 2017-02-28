#!/usr/bin/env groovy
node {
  stage('Checkout') {
    checkout scm
  }

  // Run as many tests as possible in parallel.
  String[] vagrantVersions = ["1.9.1", "1.9.2"]
  stage('Test') {

    def buildJobs = [:]

    buildJobs["rspec"] = {
      docker.build("jenkins/ruby:2.2.6").inside('-v /opt/gemcache:/opt/gemcache') {
        sh """#!/bin/bash -ex
          bundle install --path /opt/gemcache
          bundle exec rspec
        """
      }
    }

    for (int i = 0; i < vagrantVersions.length; i++) {
      def index = i //if we tried to use i below, it would equal 4 in each job execution.
      def vagrantVersion = vagrantVersions[index]

      buildJobs["vagrant-${vagrantVersion}"] = {

        docker.image("myoung34/vagrant:${vagrantVersion}").inside('-v /opt/gemcache:/opt/gemcache') {
          sh """#!/bin/bash -ex
            temp_dir="/tmp/\$(cat /proc/sys/kernel/random/uuid)"
            cp -r \$(pwd) \$temp_dir
            cd \$temp_dir
            gem build *.gemspec
            /usr/bin/vagrant plugin install *.gem
            bundle install --path /opt/gemcache --without development plugins
            export VAGRANT_VERSION=\$(echo ${vagrantVersion} | sed 's/\\.//g')
            bundle exec kitchen test ^[^singleton-]
          """
        }

      }
    }

    parallel( buildJobs )
  }

  for (int i = 0; i < vagrantVersions.length; i++) {
    def index = i //if we tried to use i below, it would equal 4 in each job execution.
    def vagrantVersion = vagrantVersions[index]


    stage("singleton vagrant-${vagrantVersion}") {
      docker.image("myoung34/vagrant:${vagrantVersion}").inside('-v /opt/gemcache:/opt/gemcache') {
        sh """#!/bin/bash -ex
          gem build *.gemspec
          /usr/bin/vagrant plugin install *.gem
          bundle install --path /opt/gemcache --without development plugins
          bundle exec kitchen destroy all
          rm -rf .kitchen
          export VAGRANT_VERSION=\$(echo ${vagrantVersion} | sed 's/\\.//g')
          bundle exec kitchen test ^singleton-
        """
      }
    }
  }
    
  stage("Cleanup") {
    deleteDir()
  }
}
