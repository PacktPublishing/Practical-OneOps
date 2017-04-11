# Cookbook Name:: etcd
# Attributes:: default
#
# Author : OneOps
# Apache License, Version 2.0

# Etcd binary attributes
default[:etcd][:arch] = 'linux-amd64'
default[:etcd][:extn] = 'tar.gz'
default[:etcd][:extract_path] = '/opt/etcd'

# Etcd config attributes
default[:etcd][:conf_file] = '/etc/etcd/etcd.conf'
default[:etcd][:conf_location] = '/etc/etcd'
default[:etcd][:working_location] = '/var/lib/etcd'
default[:etcd][:systemd_file] = '/usr/lib/systemd/system/etcd.service'

# Etcd default mirror
default[:etcd][:release_url] = 'https://github.com/coreos/etcd/releases/download/v$version/etcd-v$version-$arch.$extn'
