#
# Cookbook Name:: ansiblerole
# Provider:: galaxy
#

# Existing copyright notice
#
# Author:: Seth Chisamore <schisamo@chef.io>
# Cookbook Name:: python
# Provider:: pip
#
# Copyright:: 2011, Chef Software, Inc <legal@chef.io>
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
#

require 'chef/mixin/shell_out'
require 'chef/mixin/language'
include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

action :run do
  description = "Running playbook via #{new_resource.name}"

  converge_by(description) do
    Chef::Log.info(description)
    status = run_playbook()
    if status
      new_resource.updated_by_last_action(true)
    end
  end

end

action :install_file do
  description = "install role via file #{new_resource.name}"
  converge_by(description) do
    Chef::Log.info("Installing role from file #{new_resource}")
    status = install_role_from_file()
    if status
      new_resource.updated_by_last_action(true)
    end 
  end
end

action :install do
  if new_resource.version != nil && new_resource.version != current_resource.version
    install_version = new_resource.version
  elsif current_resource.version == nil
    install_version = candidate_version
  end

  if install_version
    description = "install package #{new_resource} version #{install_version}"
    converge_by(description) do
      Chef::Log.info("Installing #{new_resource} version #{install_version}")
      status = install_role(install_version)
      if status
        new_resource.updated_by_last_action(true)
      end
    end
  end
end

action :remove do
  if removing_role?
    description = "remove role #{new_resource}"
    converge_by(description) do
      Chef::Log.info("Removing #{new_resource}")
      remove_package(new_resource.version)
      new_resource.updated_by_last_action(true)
    end
  end
end

def removing_role?
  if current_resource.version.nil?
    false # nothing to remove
  elsif new_resource.version.nil?
    true # remove any version of a package
  elsif new_resource.version == current_resource.version
    true # remove the version we have
  else
    false # we don't have the version we want to remove
  end
end

# these methods are the required overrides of
# a provider that extends from Chef::Provider::Package
# so refactoring into core Chef should be easy

def load_current_resource
  @current_resource = Chef::Resource::AnsibleroleGalaxy.new(new_resource.name)
  @current_resource.name(new_resource.name)
  @current_resource.version(nil)

  unless current_installed_version.nil?
    @current_resource.version(current_installed_version)
  end

  @current_resource
end

def current_installed_version
  @current_installed_version ||= begin
    out = nil
    name = new_resource.name.gsub('_', '-')
    pattern = Regexp.new("^ - #{Regexp.escape(name)} (unknown version|[0-9]+.[0-9]+.[0-9]+)", true)
    shell_out("#{which_galaxy(new_resource)} list").stdout.lines.find do |line|
      out = pattern.match(line)
    end
    out.nil? ? nil : out[1]
  end
end

def candidate_version
  @candidate_version ||= begin
    # `ansible-galaxy search` doesn't return versions yet
    # `ansible-galaxy list`
    new_resource.version||'latest'
  end
end

def run_playbook()
  playbook_cmd()
end

def install_role_from_file()
  galaxy_cmd("install -r ",'')
end

def install_role(version)
  # if a version isn't specified (latest), is a source archive (ex. http://my.package.repo/SomePackage-1.0.4.zip),
  # or from a VCS (ex. git+https://git.repo/some_pkg.git) then do not append a version as this will break the source link
  if version == 'latest' || new_resource.name.downcase.start_with?('http:', 'https:') || ['git', 'hg', 'svn'].include?(new_resource.name.downcase.split('+')[0])
    version = ''
  else
    version = ",#{version}"
  end
  galaxy_cmd('install', version)
end

def remove_package(version)
  galaxy_cmd('uninstall')
end

def playbook_cmd()
  options = { :timeout => new_resource.timeout }
  environment = Hash.new
  environment.merge!(new_resource.environment) if new_resource.environment && !new_resource.environment.empty?
  shell = Mixlib::ShellOut.new("#{which_ansible_playbook(new_resource)} #{new_resource.name}", :live_stream => STDOUT, :environment => environment)
  shell.run_command
  shell.error!
end

def galaxy_cmd(subcommand, version='')
  options = { :timeout => new_resource.timeout }
  environment = Hash.new
  environment.merge!(new_resource.environment) if new_resource.environment && !new_resource.environment.empty?
  shell = Mixlib::ShellOut.new("#{which_galaxy(new_resource)} #{subcommand} #{new_resource.name}#{version}", :live_stream => STDOUT, :environment => environment)
  shell.run_command
  shell.error!
end

def which_ansible_playbook(nr)
  if ::File.exists?(node['ansible']['ansible_playbook_location'])
    node['ansible']['ansible_playbook_location']
  else
    'ansible-playbook'
  end
end

def which_galaxy(nr)
  if ::File.exists?(node['ansible']['galaxy_location'])
    node['ansible']['galaxy_location']
  else
    'ansible-galaxy'
  end
end
