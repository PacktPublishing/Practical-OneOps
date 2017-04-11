#
# Author:: Didier Bathily (<bathily@njin.fr>)
#
# Copyright 2013, njin
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

#include Chef::Resource::ApplicationBase

actions :deploy

attribute :initd_template, :kind_of => [String, NilClass], :default => nil
attribute :ivy_credentials, :kind_of => [String, NilClass], :default => nil
attribute :application_conf, :kind_of => [String, NilClass], :default => nil
attribute :log_file, :kind_of => [String, NilClass], :default => nil
attribute :http_port, :kind_of => [Integer, NilClass], :default => 80
attribute :https_port, :kind_of => [Integer, NilClass], :default => nil
attribute :app_opts, :kind_of => [String, NilClass], :default => ""
attribute :app_dir, :kind_of => [String, NilClass], :default => ""
attribute :app_name, :kind_of => [String, NilClass], :default => nil 
attribute :app_location, :kind_of => [String, NilClass], :default => nil
attribute :app_secret, :kind_of => [String, NilClass], :default => nil
