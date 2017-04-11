#
# Author:: Joshua Timberman <joshua@opscode.com>
# Cookbook Name:: couchdb
# Attributes:: couchdb
#
# Copyright 2010, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

default['couchdb']['checksum']   = ""
default['couchdb']['version']    = "1.4.0"
default['couchdb']['src_mirror']     = "http://archive.apache.org/dist/couchdb/source/#{node['couchdb']['version']}/apache-couchdb-#{node['couchdb']['version']}.tar.gz"
default['couchdb']['install_erlang'] = false

# Attributes below are used to configure your couchdb instance.
# These defaults were extracted from this url:
#  http://wiki.apache.org/couchdb/Configurationfile_couch.ini
#
# Configuration file is now removed in favor of dynamic
# generation.

default['couchdb']['config']['couchdb']['max_document_size'] = 4294967296 # In bytes (4 GB)
default['couchdb']['config']['couchdb']['max_attachment_chunk_size'] = 4294967296 # In bytes (4 GB)
default['couchdb']['config']['couchdb']['os_process_timeout'] = 5000 # In ms (5 seconds)
default['couchdb']['config']['couchdb']['max_dbs_open'] = 100
default['couchdb']['config']['couchdb']['delayed_commits'] = true
default['couchdb']['config']['couchdb']['batch_save_size'] = 1000
default['couchdb']['config']['couchdb']['batch_save_interval'] = 1000  # In ms (1 second)

#default['couchdb']['config']['httpd']['port'] = 5984
#default['couchdb']['config']['httpd']['bind_address'] = "127.0.0.1"

default['couchdb']['config']['log']['level'] = "info"
