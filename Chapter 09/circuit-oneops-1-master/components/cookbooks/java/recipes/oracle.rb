# Copyright 2016, Walmart Stores, Inc.
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


# Cookbook Name:: java
# Recipe:: oracle
#


extend Java::Util

# Wire java util to chef resources.
Chef::Resource::RubyBlock.send(:include, Java::Util)

Chef::Log.info('Starting Oracle java installation...')
Chef::Log.info("Java config parameters: #{node.java.inspect}")

version = node.java.version.to_i
pkg = node.java.jrejdk

# Server JRE is supported only for JDK7 or later
if version <= 6 && pkg == 'server-jre'
  exit_with_err "Oracle Java-#{version} #{pkg} package is not available. Use a different package/version."
end

install_dir = node.java.install_dir
sys_default = node.java.sysdefault

# Trim the binpath whitespace
node.java.binpath.strip!

if node.java.binpath.empty?
  # Automatically download the package from mirror location
  base_url, file_name, extract_dir = get_java_pkg_location
  binpath = "/usr/src/#{file_name}"

  # Download the package
  log 'Download' do
    message "Downloading #{base_url}/#{file_name} to #{binpath}..."
  end
  remote_file "#{binpath}" do
    owner 'root'
    group 'root'
    mode 0755
    source "#{base_url}/#{file_name}"
  end

else
  # User provided binary package
  binpath = node.java.binpath
  uversion, extract_dir = validate_pkg_file(binpath.split("/").last)
end


# Final install dir (Java Home)
jpath = "#{install_dir}/#{extract_dir}"


# Create JVM install directory
directory "#{install_dir}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if "test -d #{install_dir}"
end

# JDK installation
case
  when version > 6
    ruby_block "Install Oracle #{pkg} #{version}" do
      block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("tar zxf #{binpath}",
                   :cwd => "#{install_dir}",
                   :live_stream => Chef::Log::logger)
      end
      # Always install the JDK/JRE
      # not_if "test -d #{jpath}"
    end
  when version == 6
    if !::File.exist?(jpath)
      ruby_block "Install Oracle #{pkg} #{version}" do
        block do
          result = `cd #{install_dir} ; chmod +x #{binpath} && #{binpath}`
          if result.to_i != 0
            exit_with_err "Expanding/running: #{binpath} returned: exit_code: #{result.to_i.to_s} output: #{result.to_s}"
          end
        end
      end
    else
      Chef::Log.warn "#{jpath} exists. Skipping Oracle #{pkg} #{version} installtion."
    end
end



# Creating symlinks
directory '/usr/java' do
  action :create
end

link '/usr/java/default' do
  to jpath
end


# Set java alternatives
ruby_block 'Install Java Alternatives' do
  block do
    Chef::Log.info("Processing system default for #{pkg} path: #{jpath}")

    tools = get_java_tools(jpath)
    slaves = tools.map { |a| "--slave /usr/bin/#{a} #{a} #{jpath}/bin/#{a}" }.join(' ')
    Chef::Log.info("--SLAVES-- #{slaves}")

    install = Chef::Resource::Execute.new('Java Alternatives Install', run_context)
    install.command("update-alternatives --install /usr/bin/java java #{jpath}/bin/java 100 #{slaves}")
    install.run_action(:run)

    set = Chef::Resource::Execute.new('Java Alternatives set', run_context)
    set.command("update-alternatives --set java #{jpath}/bin/java")
    set.run_action(:run)

  end
  only_if { sys_default == 'true' }
end


# Java version assert
ruby_block "Java #{version} version assert" do
  block do
    exit_with_err "Java #{version} version assert failed!" if !has_java_version?(version)
  end
  only_if { sys_default == 'true' }
end


# Export JAVA_HOME
template '/etc/profile.d/java.sh' do
  source 'java.sh.erb'
  owner "root"
  group "root"
  mode 0644
  variables({
                :java_home => '/usr/java/default'
            })
end

log "Java package installtion completed!"
