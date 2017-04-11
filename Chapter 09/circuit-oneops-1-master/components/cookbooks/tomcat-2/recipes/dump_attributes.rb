# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat-2
# Recipe:: dump_attributes
# Purpose:: This recipe is used to dump defaults and calculated values for
#           Tomcat and from the metadata
#
# Copyright 2016, Walmart Stores Incorporated
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
###############################################################################

###############################################################################
# Global attributes for Tomcat ITH
###############################################################################
Chef::Log.debug("version: #{node['tomcat']['global']['version']}")
Chef::Log.debug("tomcat_user: #{node['tomcat']['global']['tomcat_user']}")
Chef::Log.debug("tomcat_group: #{node['tomcat']['global']['tomcat_group']}")
Chef::Log.debug("environment_settings: #{node['tomcat']['global']['environment_settings']}")

###############################################################################
# Attributes for context.xml Configuration
###############################################################################
Chef::Log.debug("override_context_enabled: #{node['tomcat']['context']['override_context_enabled']}")
  if (node['tomcat']['context']['override_context_enabled'] == 'true')
    Chef::Log.debug("context_tomcat: #{node['tomcat']['context']['context_tomcat']}")
  end

###############################################################################
# Attributes for server.xml Configuration
###############################################################################
Chef::Log.debug("override_server_enabled: #{node['tomcat']['server']['override_server_enabled']}")
  if (node['tomcat']['context']['override_context_enabled'] == 'true')
    Chef::Log.debug("server_tomcat: #{node['tomcat']['server']['server_tomcat']}")
  end
Chef::Log.debug("http_nio_connector_enabled: #{node['tomcat']['server']['http_nio_connector_enabled']}")
Chef::Log.debug("port: #{node['tomcat']['server']['port']}")
Chef::Log.debug("https_nio_connector_enabled: #{node['tomcat']['server']['https_nio_connector_enabled']}")
Chef::Log.debug("ssl_port: #{node['tomcat']['server']['ssl_port']}")
Chef::Log.debug("max_threads: #{node['tomcat']['server']['max_threads']}")
Chef::Log.debug("advanced_security_options: #{node['tomcat']['server']['advanced_security_options']}")
Chef::Log.debug("tlsv11_protocol_enabled: #{node['tomcat']['server']['tlsv11_protocol_enabled']}")
Chef::Log.debug("tlsv12_protocol_enabled: #{node['tomcat']['server']['tlsv12_protocol_enabled']}")
Chef::Log.debug("advanced_nio_connector_config: #{node['tomcat']['server']['advanced_nio_connector_config']}")
Chef::Log.debug("autodeploy_enabled: #{node['tomcat']['server']['autodeploy_enabled']}")
Chef::Log.debug("http_methods: #{node['tomcat']['server']['http_methods']}")
Chef::Log.debug("enable_method_get: #{node['tomcat']['server']['enable_method_get']}")
Chef::Log.debug("enable_method_put: #{node['tomcat']['server']['enable_method_put']}")
Chef::Log.debug("enable_method_post: #{node['tomcat']['server']['enable_method_post']}")
Chef::Log.debug("enable_method_delete: #{node['tomcat']['server']['enable_method_delete']}")
Chef::Log.debug("enable_method_options: #{node['tomcat']['server']['enable_method_options']}")
Chef::Log.debug("enable_method_head: #{node['tomcat']['server']['enable_method_head']}")

###############################################################################
# Attributes set in the setenv.sh script
###############################################################################
Chef::Log.debug("java_options: #{node['tomcat']['java']['java_options']}")
Chef::Log.debug("system_properties: #{node['tomcat']['java']['system_properties']}")
Chef::Log.debug("startup_params: #{node['tomcat']['java']['startup_params']}")
Chef::Log.debug("mem_max: #{node['tomcat']['java']['mem_max']}")
Chef::Log.debug("mem_start: #{node['tomcat']['java']['mem_start']}")

###############################################################################
# Attributes to control log settings
###############################################################################
Chef::Log.debug("access_log_pattern: #{node['tomcat']['logs']['access_log_pattern']}")

###############################################################################
# Attributes for Tomcat instance startup and shutdown processes
###############################################################################
Chef::Log.debug("stop_time: #{node['tomcat']['startup_shutdown']['stop_time']}")
if node.workorder.rfcCi.ciAttributes.has_key?('pre_shutdown_command')
  Chef::Log.debug("pre_shutdown_command: #{node['tomcat']['startup_shutdown']['pre_shutdown_command']}")
end
if node.workorder.rfcCi.ciAttributes.has_key?('post_shutdown_command')
  Chef::Log.debug("post_shutdown_command: #{node['tomcat']['startup_shutdown']['post_shutdown_command']}")
end
if node.workorder.rfcCi.ciAttributes.has_key?('pre_startup_command')
  Chef::Log.debug("pre_startup_command: #{node['tomcat']['startup_shutdown']['pre_startup_command']}")
end
if node.workorder.rfcCi.ciAttributes.has_key?('post_startup_command')
  Chef::Log.debug("post_startup_command: #{node['tomcat']['startup_shutdown']['post_startup_command']}")
end
Chef::Log.debug("time_to_wait_before_shutdown: #{node['tomcat']['startup_shutdown']['time_to_wait_before_shutdown']}")
Chef::Log.debug("polling_frequency_post_startup_check: #{node['tomcat']['startup_shutdown']['polling_frequency_post_startup_check']}")
Chef::Log.debug("max_number_of_retries_for_post_startup_check: #{node['tomcat']['startup_shutdown']['max_number_of_retries_for_post_startup_check']}")

###############################################################################
# Tomcat variables not in metadata.rb
###############################################################################
Chef::Log.debug("tomcat_install_dir: #{node['tomcat']['tomcat_install_dir']}")
Chef::Log.debug("config_dir: #{node['tomcat']['config_dir']}")
Chef::Log.debug("instance_dir: #{node['tomcat']['instance_dir']}")
Chef::Log.debug("tarball: #{node['tomcat']['tarball']}")
Chef::Log.debug("download_destination: #{node['tomcat']['download_destination']}")
Chef::Log.debug("logfiles_path: #{node['tomcat']['logfiles_path']}")
Chef::Log.debug("logfiles_path_dir: #{node['tomcat']['logfiles_path_dir']}")
Chef::Log.debug("webapp_install_dir: #{node['tomcat']['webapp_install_dir']}")
Chef::Log.debug("webapp_link: #{node['tomcat']['webapp_link']}")
Chef::Log.debug("tmp_dir: #{node['tomcat']['tmp_dir']}")
Chef::Log.debug("tmp_link: #{node['tomcat']['tmp_link']}")
Chef::Log.debug("work_dir: #{node['tomcat']['work_dir']}")
Chef::Log.debug("work_link: #{node['tomcat']['work_link']}")
Chef::Log.debug("catalina_dir: #{node['tomcat']['catalina_dir']}")
Chef::Log.debug("catalina_link: #{node['tomcat']['catalina_link']}")
Chef::Log.debug("keystore_dir: #{node['tomcat']['keystore_dir']}")
Chef::Log.debug("keystore_link: #{node['tomcat']['keystore_link']}")
Chef::Log.debug("keystore_path: #{node['tomcat']['keystore_path']}")
Chef::Log.debug("context_dir: #{node['tomcat']['context_dir']}")
Chef::Log.debug("scripts_dir: #{node['tomcat']['scripts_dir']}")
Chef::Log.debug("keystore_pass: #{node['tomcat']['keystore_pass']}")
Chef::Log.debug("shutdown_port: #{node['tomcat']['shutdown_port']}")
Chef::Log.debug("use_security_manager: #{node['tomcat']['use_security_manager']}")
Chef::Log.debug("ssl_configured_ciphers: #{node['tomcat']['ssl_configured_ciphers']}")
Chef::Log.debug("java_home: #{node['java']['java_home']}")
Chef::Log.debug("home: #{node['tomcat']['home']}")
Chef::Log.debug("base: #{node['tomcat']['base']}")
Chef::Log.debug("key: This key will not be printed out here. Please log into the server to read the key.")
