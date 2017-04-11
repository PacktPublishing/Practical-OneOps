#
# Cookbook Name:: activemq
# Recipe:: add
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "activemq::externalstorage"

tmp = Chef::Config[:file_cache_path]
version = node['activemq']['version']
activemq_home = "#{node['activemq']['installpath']}/apache-activemq-#{version}"
logpath="#{node['activemq']['logpath']}"

tarball = "activemq/#{version}/apache-activemq-#{version}-bin.tar.gz"
dest_file = "#{tmp}/apache-activemq-#{version}-bin.tar.gz"

runasuser ="#{node['activemq']['runasuser']}"

# Find major, minor version
vMj, vMn = version.split(".")
vminorjetty=12
vMinor=vMn.to_i
# Config templates are same for jetty 5.13 and earlier
if vMinor >= 13
    vminorjetty=13
end
config_ver = "#{vMj+ '.' + vminorjetty.to_s == '5.12' ? '5.12' :''}"

vminoramq=11
# Config templates are same for activemq.xml 5.12 and earlier
if vMinor >= 12
    vminoramq=12
end

config_ver_amqxml = "#{vMj+ '.' + vminoramq.to_s == '5.11' ? '5.11' :''}"

Chef::Log.info("config_ver:  #{config_ver}")

# Try component mirrors first, if empty try cloud mirrors, if empty use cookbook mirror attribute
source_list = JSON.parse(node.activemq.mirrors).map { |mirror| "#{mirror}/#{tarball}" }
if source_list.empty?
    cloud_name = node[:workorder][:cloud][:ciName]
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
    source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}/#{tarball}" }
end
source_list = ["#{node['activemq']['src_mirror']}/#{tarball}"] if source_list.empty?

users=[]
#usersstr=''

JSON.parse(node[:activemq][:users]).keys.each do |k|
    users.push(k)
end

userstr=users.join(",")
Chef::Log.info("Users:  #{userstr}")

# Download ActiveMQ binary
unless File.exists?("#{activemq_home}/bin/activemq")

    shared_download_http source_list.join(',') do
        path dest_file
        action :create
        if node[:activemq][:checksum] && !node[:activemq][:checksum].empty?
            checksum node[:activemq][:checksum]
        end
    end
end

directory "#{node[:activemq][:datapath]}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "#{node[:activemq][:installpath]}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "#{logpath}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "#{node[:activemq][:enckeypath]}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

directory "#{node[:activemq][:adminconsolekeystore]}" do
    mode 00644
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

#extract the tar
execute "tar zxf #{dest_file}" do
    cwd "#{node['activemq']['installpath']}"
    only_if { ::File.exists?(dest_file) }
end

arch = (node['kernel']['machine'] == 'x86_64') ? 'x86-64' : 'x86-32'

#change permission
file "#{activemq_home}/bin/activemq" do
    owner "#{runasuser}"
    group "#{runasuser}"
    mode '0755'
end

link '/etc/init.d/activemq' do
    to "#{activemq_home}/bin/linux-#{arch}/activemq"
    owner "#{runasuser}"
    group "#{runasuser}"
end

# control script via template for adminstatus / cloud priority
template "#{activemq_home}/bin/linux-#{arch}/activemq" do
    source "init_activemq.erb"
    mode 0755
end

# Symlink so the default wrapper.conf can find the native wrapper library
link "#{activemq_home}/bin/linux" do
    to "#{activemq_home}/bin/linux-#{arch}"
    owner "#{runasuser}"
    group "#{runasuser}"
end

include_recipe "activemq::stop"

template "#{activemq_home}/bin/linux/wrapper.conf" do
    source "wrapper.conf.erb"
    mode 0644
    variables({
        :datadirectory  => node[:activemq][:datapath],
        :logpath =>  node[:activemq][:logpath],
        :logsize => node[:activemq][:logsize]
    })
end

# Create a generic 'activemq' symlink for easy access.
link "#{node['activemq']['installpath']}/activemq" do
    to "#{activemq_home}"
    owner "#{runasuser}"
    group "#{runasuser}"
end


# Symlink the wrapper's pidfile location into /var/run
link '/var/run/activemq.pid' do
    to "#{activemq_home}/bin/linux/ActiveMQ.pid"
    not_if 'test -f /var/run/activemq.pid'
    owner "#{runasuser}"
    group "#{runasuser}"
end

link '/var/run/activemq.pid' do
    to "#{activemq_home}/bin/ActiveMQ.pid"
    not_if 'test -f /var/run/activemq.pid'
    owner "#{runasuser}"
    group "#{runasuser}"
end

template "#{activemq_home}/conf/jetty-realm.properties" do
    source 'jetty-realm.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminpassword]
    })
    mode 0644
end

template "#{activemq_home}/conf/jetty.xml" do
    source "jetty#{config_ver}.xml.erb"
    variables({
        :adminconsoleport => node[:activemq][:adminconsoleport],
        :authenabled => node[:activemq][:authenabled]
    })
    mode 0644
end

template "#{activemq_home}/conf/activemq.xml" do
    source "activemq#{config_ver_amqxml}.xml.erb"
    variables({
        :datadirectory => node[:activemq][:datapath],
        :storeusage => node[:activemq][:storeusage],
        :tempusage => node[:activemq][:tempusage],
        :jvmheap => node[:activemq][:jvmheap]
    })
    mode 0644
end

# Add brokerusename and brokerpassword backward compatibilty

file "#{node['activemq']['enckeypath']}#{node['activemq']['enckey']}" do
    encpassword =Activemq::Helper::getencpasswordkey(node)
    content encpassword
    mode '0644'
    action :create_if_missing
    not_if {::File.exists?("#{node['activemq']['enckeypath']}#{node['activemq']['enckey']}")}
end

cookbook_file "#{activemq_home}/amq-messaging-resource.jar" do
    source 'amq-messaging-resource.jar'
    owner "#{runasuser}"
    group "#{runasuser}"
    mode '0777'
    action :create
end

encypwdusers=Hash.new

#get encrypted pwds and users[]
ruby_block 'Encryption-Required' do
  block do
    Chef::Resource::RubyBlock.send(:include, Activemq::Helper)
       enckey=`cat "#{node['activemq']['enckeypath']}#{node['activemq']['enckey']}"`
        Activemq::Helper::encrypt(node, node[:activemq][:adminpassword],enckey,"adminencpwd")

        if node[:activemq][:brokerpassword].to_s != ''
         Activemq::Helper::encrypt(node, node[:activemq][:brokerpassword],enckey,"brokerencpwd")
        end

        JSON.parse(node[:activemq][:users]).each do |key,val|
            Activemq::Helper::encrypt(node, "#{val}",enckey,"")
            encypwdusers["#{key}"] ="ENC(#{node[:activemq][:encpwd]})"
        end
  end
    only_if {node.activemq.pwdencyenabled == 'true' && ::File.exists?("#{node['activemq']['enckeypath']}#{node['activemq']['enckey']}")}
end

ruby_block 'Encryption-Not-Required' do
  block do
    node.set[:activemq][:adminencpwd] =node[:activemq][:adminpassword]
    JSON.parse(node[:activemq][:users]).each do |key,val|
        encypwdusers["#{key}"] ="#{val}"
     end
    end
  only_if {node.activemq.pwdencyenabled == 'false'}
end

template "#{activemq_home}/conf/credentials.properties" do
    source 'credentials.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminpassword],
        :brokerusername => node[:activemq][:brokerusername],
        :brokerpassword => node[:activemq][:brokerpassword],
    })
    only_if {node.activemq.pwdencyenabled == 'false'}
    mode 0644
end

template "#{activemq_home}/conf/credentials-enc.properties" do
    source 'credentials-enc.properties.erb'
    variables( lazy {{
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminencpwd],
        :brokerusername => node[:activemq][:brokerusername],
        :brokerpassword => node[:activemq][:brokerencpwd],
        :encypwdusers => encypwdusers
    }})
    mode 0644
    only_if {node.activemq.pwdencyenabled == 'true'}
end

template "#{activemq_home}/conf/users.properties" do
    source 'users.properties.erb'
     variables( lazy {{
        :adminusername => node[:activemq][:adminusername],
        :adminpassword => node[:activemq][:adminencpwd],
        :encypwdusers => encypwdusers
     }})
    mode 0644
end

template "#{activemq_home}/conf/groups.properties" do
    source 'groups.properties.erb'
    variables({
        :adminusername => node[:activemq][:adminusername],
        :users => userstr
    })
    mode 0644
end

template "#{activemq_home}/conf/log4j.properties" do
    source 'log4j.properties.erb'
    variables({
        :logpath => node[:activemq][:logpath],
        :logsize => node[:activemq][:logsize]
    })
    mode 0644
end

template "#{activemq_home}/webapps/admin/decorators/header.jsp" do
    source "header.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/message.jsp" do
    source "message.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/browse.jsp" do
    source "browse.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/queues.jsp" do
    source "queues.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/subscribers.jsp" do
   source "subscribers.jsp.erb"
   mode 0644
end

template "#{activemq_home}/webapps/admin/topics.jsp" do
    source "topics.jsp.erb"
    mode 0644
end

template "#{activemq_home}/webapps/admin/connection.jsp" do
   source "connection.jsp.erb"
   mode 0644
end

template "#{activemq_home}/conf/jmx.access" do
    source "jmx.access.erb"
    mode 0644
end

template "#{activemq_home}/conf/login.config" do
    source "login.config.erb"
    mode 0644
end

template "#{activemq_home}/conf/jmx.password" do
    source "jmx.password.erb"
    mode 0644
end

execute "chown-user" do
    command "chown -R #{runasuser}:#{runasuser} /#{node['activemq']['installpath']}/activemq"
    command "chown -R #{runasuser}:#{runasuser} /#{node['activemq']['installpath']}/apache*"
    action :run
end

directory '/etc/sysconfig' do
  owner 'activemq'
  group 'activemq'
end

template '/etc/sysconfig/activemq' do
  source 'sysconfig.erb'
  mode 0755
  owner 'activemq'
  group 'activemq'
end

execute "Move API" do
    cwd "#{activemq_home}/webapps"
    command "rm -rf api "
    only_if {node.activemq.restapisupport == 'false' && File.exists?("#{activemq_home}/webapps/api/WEB-INF/web.xml")}
end

directory "#{node[:activemq][:datapath]}" do
    mode 00755
    owner "#{runasuser}"
    group "#{runasuser}"
    recursive true
end

if node.workorder.cloud.ciAttributes.priority == "1"
    service 'activemq' do
        supports :restart => true, :status => true, :stop => true, :start => true
        action [:enable, :start]
    end
else
    # disable and stop secondary
    service 'activemq' do
        supports :restart => true, :status => true, :stop => true, :start => true
        action [:disable, :stop]
    end
end

# Monitor scripts
template '/opt/nagios/libexec/check_activemq.rb' do
    source 'check_activemq.rb.erb'
    mode 0755
    owner 'oneops'
    group 'oneops'
end

template '/opt/nagios/libexec/check_activemq_process.sh' do
    source 'check_activemq_process.sh.erb'
    mode 0755
    owner 'oneops'
    group 'oneops'
end

template '/opt/nagios/libexec/check_activemq_mem.rb' do
    source 'check_activemq_mem.rb.erb'
    mode 0755
    owner 'oneops'
    group 'oneops'
end
