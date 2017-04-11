# Cookbook Name:: docker_engine
# Attributes:: default
#
# Author : OneOps
# Apache License, Version 2.0

# Docker binary attributes
default[:docker_engine][:service] = 'docker'
default[:docker_engine][:package] = 'docker-engine'
default[:docker_engine][:release] = '1.el7.centos'
default[:docker_engine][:arch] = 'x86_64'
default[:docker_engine][:api_gem] = 'docker-api-1.28.0.gem'

# RHEL Platform config
default[:docker_engine][:tlscacert_file] = '/etc/docker/ca.pem'
default[:docker_engine][:tlscert_file] = '/etc/docker/cert.pem'
default[:docker_engine][:tlskey_file] = '/etc/docker/key.pem'

# Default Daemon socket(s) to connect to
default[:docker_engine][:def_unix_sock] = '/var/run/docker.sock'
default[:docker_engine][:systemd_path] = '/usr/lib/systemd/system'
default[:docker_engine][:systemd_drop_in_path] = '/etc/systemd/system/docker.service.d'

default[:docker_engine][:repo_file] = '/etc/yum.repos.d/docker.repo'
default[:docker_engine][:default_repo] = 'https://yum.dockerproject.org/repo/main/centos/$releasever/'