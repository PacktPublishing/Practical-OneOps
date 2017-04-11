# override attribute defaults w/ values from workorder
node.set['tomcat_owner'] = node['tomcat']['user']
node.set['tomcat_group'] = node['tomcat']['group']

if node['tomcat'].has_key?("tomcat_user") && !node['tomcat']['tomcat_user'].empty?
  node.set['tomcat_owner'] = node['tomcat']['tomcat_user']
end

if node['tomcat'].has_key?("tomcat_group") && !node['tomcat']['tomcat_group'].empty?
  node.set['tomcat_group'] = node['tomcat']['tomcat_group']
end

(node['tomcat'].has_key?('protocol') && !node['tomcat']['protocol'].empty?) ?
    node.set['tomcat']['connector']['protocol'] = node['tomcat']['protocol'] :
    node.set['tomcat']['connector']['protocol'] = 'HTTP/1.1'

(node['tomcat'].has_key?('advanced_connector_config') && !node['tomcat']['advanced_connector_config'].empty?) ?
    node.set['tomcat']['connector']['advanced_connector_config'] = node['tomcat']['advanced_connector_config'] :
    node.set['tomcat']['connector']['advanced_connector_config'] = '{"connectionTimeout":"20000"}'

Chef::Log.info(" protocol  #{node['tomcat']['connector']['protocol']} - connector config #{node['tomcat']['connector']['advanced_connector_config']} ssl_configured : #{node['tomcat']['connector']['ssl_configured']}")

tomcat_version_name = "tomcat"+node.workorder.rfcCi.ciAttributes.version[0,1]
node.set['tomcat']['tomcat_version_name'] = tomcat_version_name

#Fixed the defaults for executor thread pool, uses executor.
node.set['tomcat']['executor']['executor_name']=node['tomcat']['executor_name']
node.set['tomcat']['executor']['max_threads']= node['tomcat']['max_threads']
node.set['tomcat']['executor']['min_spare_threads']=node['tomcat']['min_spare_threads']

depends_on=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }
depends_on_keystore=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Keystore/ }

Chef::Log.info("retrieving keystore location from keyStore but only if we depend on one")

if (!depends_on_keystore.nil? && !depends_on_keystore.empty?)
    Chef::Log.info("do depend on keystore, with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
    #stash values which will be needed in server.xml template .erb
    #node.set['tomcat']['keystore_path'] = depends_on_keystore[0].ciAttributes.keystore_filename
    node.set['tomcat']['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']

    #node.set['tomcat']['keystore_pass'] = depends_on_keystore[0].ciAttributes.keystore_password
    node.set['tomcat']['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
    Chef::Log.info("stashed keystore_path: #{node['tomcat']['keystore_path']} ")
end

#If HTTPS and HTTP are disabled then warn the user that they may not be able to communicate with tomcat
if ((node['tomcat']['keystore_path'] == nil || node['tomcat']['keystore_path'].empty?) && (node['tomcat']['http_connector_enabled'] == nil || node['tomcat']['http_connector_enabled']=='false'))
  Chef::Log.warn("HTTP and HTTPS are disabled, this may result in no communication to the tomcat instance.")
end

#If HTTPS is enabled by adding a certificate and keystore, define the TLS protcols allowed.
#If HTTPS is enabled and the user manually disabled all TLS protocols from the UI, TLSv1.2 is enabled.
if (node['tomcat']['keystore_path'] != nil  && !node['tomcat']['keystore_path'].empty?)
  node.set['tomcat']['connector']['ssl_configured_protocols'] = ""
  if (node['tomcat']['tlsv1_protocol_enabled'] == 'true')
    node.set['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1,")
  end
  if (node['tomcat']['tlsv11_protocol_enabled'] == 'true')
    node['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1.1,")
  end
  if (node['tomcat']['tlsv12_protocol_enabled'] == 'true')
    node['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1.2,")
  end
  node['tomcat']['connector']['ssl_configured_protocols'].chomp!(",")
  if (node['tomcat']['connector']['ssl_configured_protocols'] == "")
    Chef::Log.warn("HTTPS is enabled,but all TLS protocols were disabled.  Defaulting to TLSv1.2 only.")
    node.set['tomcat']['connector']['ssl_configured_protocols'] = "TLSv1.2"
  end
end

#Ignore foodcritic(FC024) warnings.  We only have a subset of OSes available
service "tomcat" do
  only_if { File.exists?('/etc/init.d/' + tomcat_version_name) }
  service_name tomcat_version_name
  case node["platform"]
  when "centos","redhat","fedora" # ~FC024
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => true, :status => true
  end
end

include_recipe "tomcat::stop"

if ( node.workorder.rfcCi.ciBaseAttributes.has_key?("version") &&
   node.workorder.rfcCi.ciBaseAttributes["version"] != node.tomcat.version ) ||
   ( node.workorder.rfcCi.ciBaseAttributes.has_key?("install_type") &&
   node.workorder.rfcCi.ciBaseAttributes["install_type"] != node.tomcat.install_type )
  include_recipe "tomcat::cleanup"
end

case node.tomcat.install_type
when "repository"
  include_recipe "tomcat::add_repo"
when "binary"
  include_recipe "tomcat::add_binary"
else
  exit_with_error "unsupported install_type: #{node.tomcat.install_type}"
end

template "/etc/logrotate.d/tomcat" do
  source "logrotate.erb"
  owner "root"
  group "root"
  mode "0755"
end

cron "logrotatecleanup" do
  minute '0'
  command "ls -t1 #{node.tomcat.access_log_dir}/access_log*|tail -n +7|xargs rm -r"
  mailto '/dev/null'
  action :create
end

cron "logrotate" do
  minute '0'
  command "sudo /usr/sbin/logrotate /etc/logrotate.d/tomcat"
  mailto '/dev/null'
  action :create
end

#Ignore foodcritic(FC023) warning here.  Looks for the file resource and since it cannot find it the recipe fails if we use the only_if directive
if (!depends_on.nil? && !depends_on.empty? && File.exists?('/etc/init.d/' + tomcat_version_name)) # ~FC023
#delete the tomcat init.d daemon
	file '/etc/init.d/'+ tomcat_version_name do
		action :delete
	end
end

template "/opt/nagios/libexec/check_tomcat.rb" do
  source "check_tomcat.rb.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end

template "/opt/nagios/libexec/check_ecv.rb" do
  source "check_ecv.rb.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end

include_recipe 'tomcat::versionstatus'
template "/opt/nagios/libexec/check_tomcat_app_version.sh" do
  source "check_tomcat_app_version.sh.erb"
   variables({
     :versioncheckscript => node['versioncheckscript'],
    });
  owner "oneops"
  group "oneops"
  mode "0755"
end

['webapp_install_dir','log_dir','work_dir','context_dir','webapp_dir'].each do |dir|
  dir_name = node['tomcat'][dir]
  directory dir_name do
    action :create
    recursive true
    not_if "test -d #{dir_name}"
  end
  execute "chown -R #{node.tomcat_owner}:#{node.tomcat_group} #{dir_name}"
end

link node['tomcat']['webapp_install_dir'] do
  to node['tomcat']['webapp_dir']
  owner node.tomcat_owner
  group node.tomcat_group
  action :create
  not_if "test -d #{node['tomcat']['webapp_install_dir']}"
end


if (!depends_on.nil? && !depends_on.empty? && depends_on[0][:rfcAction] != "delete")
	include_recipe "javaservicewrapper::restart"
else
	service "tomcat" do
    service_name tom_ver
  	action [:enable]
  end
  include_recipe "tomcat::restart"

end
