#Get Install Information from defaults
install_root_dir = node['diagnostic-cache']['install_root_dir']
install_app_dir = node['diagnostic-cache']['install_app_dir']
install_log_dir = node['diagnostic-cache']['log_dir']
install_target_dir = "#{install_root_dir}#{install_app_dir }"

cache_user = node['diagnostic-cache']['user']
cache_group = node['diagnostic-cache']['group']

# CI values
ci = node.workorder.rfcCi.ciAttributes
logfiles_path = ci['logfiles_path']
graphite_servers = ci['graphite_servers']
graphite_prefix = ci['graphite_prefix']
graphite_logfiles_path = ci['graphite_logfiles_path']

ns_path = node.workorder.rfcCi.nsPath.split(/\//)
oo_org=ns_path[1]
oo_assembly=ns_path[2]
oo_env=ns_path[3]
oo_platform=ns_path[5]
oo_cloud=node.workorder.cloud.ciName

Chef::Log.info("diagnostic_cache::add -- ci=#{JSON.generate(ci)}")

user = nil
pass = nil
port = nil

# dynamic payload defined in the pack to get the resources
dependencies = node.workorder.payLoad.dc
dependencies.select{ |depends_on| depends_on["ciClassName"].split('.').last == 'Couchbase' }.each do |depends_on|
  ci_attributes = depends_on["ciAttributes"]
  if ci_attributes.has_key?("adminuser")
    user = ci_attributes["adminuser"]
    Chef::Log.info("User: #{user}")
    node.default['workorder']['rfcCi']['ciAttributes']['adminuser'] = user
  end

  if ci_attributes.has_key?("adminpassword")
    pass = ci_attributes["adminpassword"]
    node.default['workorder']['rfcCi']['ciAttributes']['adminpassword'] = pass
  end

  if ci_attributes.has_key?("port")
    port = ci_attributes["port"]
  end

end


directory install_log_dir do
  recursive true
  action :create
  group cache_group
  owner cache_user
  mode 0755
end

directory install_target_dir do
  recursive true
  action :create
  group cache_group
  owner cache_user
  mode 0755

end

template "#{install_target_dir}/diagnostic-cache.rb" do
  source "diagnostic-cache.erb"
  owner cache_group
  group cache_user
  mode "0755"
  variables({
                :admin_user => user,
                :admin_password => pass,
                :logfiles_path => logfiles_path
            })
end

check_cluster_health = '/opt/nagios/libexec/check_cluster_health.rb'

execute "remove_old_file" do
  user 'root'
  command "rm #{check_cluster_health}"
  only_if {::File.exists?("#{check_cluster_health}") }
end

cch_old_file_monitor  = "/home/oneops/components/cookbooks/monitor/files/default/check_cluster_health.erb"
execute "remove_old_file_from_monitor" do
  user 'root'
  command "rm #{cch_old_file_monitor}"
  only_if {::File.exists?("#{cch_old_file_monitor}") }
end

# check_cluster_health.rb is a place holder and got populated
# by check_cluster_health.erb perodically by a cron job
template "#{check_cluster_health}" do
  source "check_cluster_health.rb"
  owner 'root'
  group 'root'
  mode "0755"
  action :create
end

template "#{install_target_dir}/check_cluster_health.rb" do
  source "check_cluster_health.erb"
  owner 'root'
  group 'root'
  mode "0755"
  action :create
  variables({
                :file_name => check_cluster_health
            })
end

cron "check-cluster-health" do
  user 'root'
  minute "*/1"
  command "sudo #{install_target_dir}/check_cluster_health.rb -U #{user} -P #{pass}"
  only_if { ::File.exists?("#{install_target_dir}/check_cluster_health.rb") }
end


cron "cache-diagnostic-tool" do
  user 'root'
  minute "*/1"
  command "#{install_target_dir}/diagnostic-cache.rb"
  only_if { ::File.exists?("#{install_target_dir}/diagnostic-cache.rb") }
end

# Graphite Metrics Tool
cookbook_file "#{install_target_dir}/couchbase_monitor.rb" do
  source 'couchbase_monitor.rb'
  owner cache_group
  group cache_user
  mode 0755
end

template "#{install_target_dir}/graphite-metrics-tool.rb" do  
  source "graphite-metrics-tool.erb"
  owner cache_group
  group cache_user
  mode "0755"
  variables({
                :admin_user => user,
                :admin_password => pass,
                :graphite_servers => graphite_servers,
                :graphite_prefix => graphite_prefix,
                :graphite_logfiles_path => graphite_logfiles_path,
                :oo_org => oo_org,
                :oo_assembly => oo_assembly,
                :oo_env => oo_env,
                :oo_platform => oo_platform,
                :oo_cloud => oo_cloud,
                :couchbase_port => port,
                :install_target_dir => install_target_dir
            })
end

cron "graphite-metrics-tool" do
  user 'root'
  minute "*/1"
  command "#{install_target_dir}/graphite-metrics-tool.rb"
  only_if { ::File.exists?("#{install_target_dir}/graphite-metrics-tool.rb") }
end


# Couchbase monitoring file
cookbook_file '/opt/nagios/libexec/check_port.pl' do
  source 'check_port.pl'
  owner 'root'
  group 'root'
  mode 0755
end

cookbook_file '/opt/nagios/libexec/check_http_admin_console.sh' do
  source 'check_http_admin_console.sh'
  owner 'root'
  group 'root'
  mode 0755
end


current_compute_attributes = node.workorder.payLoad.ManagedVia[0].ciAttributes
current_hypervisor = current_compute_attributes.has_key?('hypervisor') ? current_compute_attributes.hypervisor : ''  
current_ip = current_compute_attributes.public_ip

# Count number of computes that have the same hypervisor value but different ip
shared_hypervisor_count = node.workorder.payLoad.RequiresComputes.count { |n| 
  n.ciAttributes.has_key?('hypervisor') && n.ciAttributes.hypervisor == current_hypervisor && n.ciAttributes.public_ip != current_ip 
}

template "/opt/nagios/libexec/check_shared_hypervisor.rb" do  
  source "check_shared_hypervisor.erb"
  owner 'root'
  group 'root'
  mode "0755"
  variables({
                :shared_hypervisor_count => shared_hypervisor_count
            })
end
