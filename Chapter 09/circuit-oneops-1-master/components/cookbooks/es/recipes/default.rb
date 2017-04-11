[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

Erubis::Context.send(:include, Extensions::Templates)

include_recipe 'es::wire_ci_attr'
elasticsearch = "elasticsearch-#{node.elasticsearch[:version]}"

# service 'elasticsearch' do
  # action :stop
# end

include_recipe "ark"

# Create user and group
#
group node.elasticsearch[:user] do
  action :create
  system true
end

user node.elasticsearch[:user] do
  comment "ElasticSearch User"
  home    "#{node.elasticsearch[:dir]}/elasticsearch"
  shell   "/bin/bash"
  gid     node.elasticsearch[:user]
  supports :manage_home => false
  action  :create
  system true
end

# FIX: Work around the fact that Chef creates the directory even for `manage_home: false`
bash "remove the elasticsearch user home" do
  user    'root'
  code    "rm -rf  #{node.elasticsearch[:dir]}/elasticsearch"

  not_if  "test -L #{node.elasticsearch[:dir]}/elasticsearch"
  only_if "test -d #{node.elasticsearch[:dir]}/elasticsearch"
end

ci = node.workorder.rfcCi
version_update = ci.has_key?("ciBaseAttributes") && ci["ciBaseAttributes"].has_key?("version") && ci["ciBaseAttributes"]["version"] != ci["ciAttributes"]["version"]
Chef::Log.info("version_update value is #{version_update}")
   service 'elasticsearch' do
     action :stop unless !version_update
   end

# Create ES directories
#
[ node.elasticsearch[:path][:conf], node.elasticsearch[:path][:logs], node.elasticsearch[:pid_path] ].each do |path|
  directory path do
    owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
    recursive true
    action :create
  end
end

# Create data path directories
#
data_paths = node.elasticsearch[:path][:data].is_a?(Array) ? node.elasticsearch[:path][:data] : node.elasticsearch[:path][:data].split(',')

data_paths.each do |path|
  directory path.strip do
    owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755
    recursive true
    action :create
  end
end

# Create service
#
init_path = ""
if node[:elasticsearch][:version].start_with?("2")
  init_path = "elasticsearch-2.init.erb"
else
  init_path = "elasticsearch.init.erb"
end  

template "/etc/init.d/elasticsearch" do
  source "#{init_path}"
  owner 'root' and mode 0755
end

service "elasticsearch" do
  supports :status => true, :restart => true
  action [ :enable ]
end

# Download, extract, symlink the elasticsearch libraries and binaries
#
ark_prefix_root = node.elasticsearch[:dir] || node.ark[:prefix_root]
ark_prefix_home = node.elasticsearch[:dir] || node.ark[:prefix_home]

ark "elasticsearch" do
  url   node.elasticsearch[:download_url]
  owner node.elasticsearch[:user]
  group node.elasticsearch[:user]
  version node.elasticsearch[:version]
  has_binaries ['bin/elasticsearch', 'bin/plugin']
  checksum node.elasticsearch[:checksum]
  prefix_root   ark_prefix_root
  prefix_home   ark_prefix_home

  notifies :start,   'service[elasticsearch]'
  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]

  not_if do
    link   = "#{node.elasticsearch[:dir]}/elasticsearch"
    target = "#{node.elasticsearch[:dir]}/elasticsearch-#{node.elasticsearch[:version]}"
    binary = "#{target}/bin/elasticsearch"

    ::File.directory?(link) && ::File.symlink?(link) && ::File.readlink(link) == target && ::File.exists?(binary)
  end
end

# Increase open file and memory limits
#
bash "enable user limits" do
  user 'root'

  code <<-END.gsub(/^    /, '')
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  END

  not_if { ::File.read("/etc/pam.d/su").match(/^session    required   pam_limits\.so/) }
end

log "increase limits for the elasticsearch user"

file "/etc/security/limits.d/10-elasticsearch.conf" do
  content <<-END.gsub(/^    /, '')
    #{node.elasticsearch.fetch(:user, "elasticsearch")}     -    nofile    #{node.elasticsearch[:limits][:nofile]}
    #{node.elasticsearch.fetch(:user, "elasticsearch")}     -    memlock   #{node.elasticsearch[:limits][:memlock]}
  END
end

# Create file with ES environment variables
#
template "elasticsearch-env.sh" do
  path   "#{node.elasticsearch[:path][:conf]}/elasticsearch-env.sh"
  source "elasticsearch-env.sh.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]
end

localIp = node[:ipaddress]

node.set['elasticsearch']['discovery']['zen']['ping']['multicast']['enabled'] = false
node.set['elasticsearch']['action']['destructive_requires_name'] = true

#
  node.set['elasticsearch']['discovery']['zen']['ping']['unicast']['hosts'] = "[#{localIp}]"
  node.default['elasticsearch']['discovery']['zen']['minimum_master_nodes'] = 1
# we don't want all of the nodes in the cluster to restart when a new node joins
  node.set['elasticsearch']['skip_restart'] = true

# Update discovery configurations
#
ci = node.workorder.rfcCi
cloud_index = ci[:ciName].split('-').reverse[1].to_i
# get only local computes in the cloud
computes = node.workorder.payLoad.has_key?('RequiresComputes')? 
      node.workorder.payLoad.RequiresComputes : {}

# This will add all the computes from the data nodes and master nodes
fqdn_depends_on = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] != 'bom.oneops.1.Fqdn' }
Chef::Log.info("----fqdn_depends_on #{fqdn_depends_on}--------------------------")
unicastNodes = '['
computes.each do |cm|
  if !fqdn_depends_on.empty? && !cm[:ciAttributes][:hostname].nil?
    if unicastNodes == '['
      unicastNodes = '["'+cm[:ciAttributes][:hostname]+'"'
    else
      unicastNodes += ',' + '"'+cm[:ciAttributes][:hostname]+'"'
    end
  else
    unless cm[:ciAttributes][:private_ip].nil?
      if unicastNodes == '['
        unicastNodes = '["'+cm[:ciAttributes][:private_ip]+'"'
      else
        unicastNodes += ',' + '"'+cm[:ciAttributes][:private_ip]+'"'
      end
    end
  end
end
unicastNodes+=']'
nodes = unicastNodes.split(",").length
Chef::Log.info("----number of nodes #{nodes}--------------------------")
Chef::Log.info("----all the nodes in cluster master+ data #{unicastNodes}--------------------------")
node.set['elasticsearch']['discovery']['zen']['ping']['unicast']['hosts'] = unicastNodes

# Get the total number of master nodes if any
totalNumMasterNodes = 0
computes.each do |cm|
  unless cm[:ciName].nil?
    if cm[:ciName].start_with? 'master-compute'
      totalNumMasterNodes += 1
    end
    Chef::Log.debug("totalNumMasterNodes  from master cluster  #{totalNumMasterNodes}")
  end
end
if totalNumMasterNodes == 0
  totalNumMasterNodes = (nodes / 2).floor + 1
  Chef::Log.debug("totalNumMasterNodes  is taken from all nodes in the absence of dedicated master nodes  #{totalNumMasterNodes}")
end
node.default['elasticsearch']['discovery']['zen']['minimum_master_nodes']= totalNumMasterNodes
    
    
# Update cluster awareness attributes
clouds =""
if(!node.workorder.rfcCi.ciAttributes.cloud_rack_zone_map.empty?)
  cloud_dc_rack_map = JSON.parse(node.workorder.rfcCi.ciAttributes.cloud_rack_zone_map)
  if(node.workorder.rfcCi.ciAttributes.has_key?("awareness_attribute"))
    cluster_awareness_attribute = node.workorder.rfcCi.ciAttributes.awareness_attribute
    node.set['elasticsearch']['cluster']['routing']['allocation']['awareness']['attributes'] = cluster_awareness_attribute
    cloud_dc_rack_map.values.uniq.each do |c|
      if(!clouds.empty?)
        clouds += ","
      end  
      clouds += c
    end
    node.set['elasticsearch']['cluster']['routing']['allocation']['awareness']['force'][cluster_awareness_attribute]['values'] = clouds
  
    local_cloud = node.workorder.cloud.ciName
    rack_zone = cloud_dc_rack_map[local_cloud]
    node.set['elasticsearch']['node'][cluster_awareness_attribute] = rack_zone
  end
end    

# Set plug-ins 
#TODO : Can externalize  in meta-data. For now adding just the KOPF plugin

if node.elasticsearch[:download_url].include? "download.elastic.co"
  install_plugin 'lmenezes/elasticsearch-kopf' , 'version' => "#{node.elasticsearch[:version]}"
else
  url = node.elasticsearch[:base_url]
  install_plugin "elasticsearch-kopf", 'url' => "#{url}", 'version' => "#{node.elasticsearch[:version]}"
end

#
# Create ES config file
#
template "elasticsearch.yml" do
  path   "#{node.elasticsearch[:path][:conf]}/elasticsearch.yml"
  source "elasticsearch.yml.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]
end

#include_recipe "es::config_directives"

# Create ES logging file
#
template "logging.yml" do
  path   "#{node.elasticsearch[:path][:conf]}/logging.yml"
  source "logging.yml.erb"
  owner node.elasticsearch[:user] and group node.elasticsearch[:user] and mode 0755

  notifies :restart, 'service[elasticsearch]' unless node.elasticsearch[:skip_restart]
end

# restart the service unless its update
service 'elasticsearch' do
  action :restart unless node.workorder.rfcCi.rfcAction == 'update' && !version_update
end
