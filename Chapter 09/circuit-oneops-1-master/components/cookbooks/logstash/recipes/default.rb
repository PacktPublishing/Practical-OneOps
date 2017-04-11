require 'json'

nodes = node.workorder.payLoad.RequiresComputes 
availability_mode = node.workorder.box.ciAttributes.availability

ci = node.workorder.rfcCi
# node.logstash[:version] = ci.version

input_version = node.logstash['version']
if !input_version.nil? && ! input_version.empty?
	node.set[:logstash][:version] = input_version
end

tmp = Chef::Config[:file_cache_path]
file_name="logstash-"+node.logstash.version+".tar.gz"
dest_file = "#{tmp}/"+file_name

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key? "mirror"
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
else
  exit_with_error "Cloud Mirror Service has not been defined"
end

logstash_source = mirrors['logstash']
if logstash_source.nil?
  Chef::Log.info("logstash source has not beed defined in cloud mirror service.. Taking default value #{node.logstash.source}")
  logstash_download_url="#{node.logstash.source}"+file_name
else
  Chef::Log.info("logstash source has been defined in cloud mirror service #{logstash_source}")
  logstash_download_url="#{logstash_source}/"+node.logstash.version+"/"+file_name
end

Chef::Log.info("Logstash downlaod url is #{logstash_download_url}")

remote_file dest_file do
  source logstash_download_url
end

untar_dir = "/opt/logstash-"+node.logstash[:version]

execute "untar_logstash" do
  command "tar -zxf #{dest_file}; rm -fr /opt/logstash ; ln -sf #{untar_dir} /opt/logstash"
  cwd "/opt"
end

logstash_inputs = ""
inputs = JSON.parse(ci.ciAttributes.inputs)
logstash_inputs = "#{inputs.join("\n")}"

logstash_filters = ""
if ci.ciAttributes.has_key?("filters") &&
      !node.workorder.rfcCi.ciAttributes.filters.empty?
  filters = JSON.parse(ci.ciAttributes.filters)
  logstash_filters = "#{filters.join("\n")}"
end

logstash_outputs = ""
outputs = JSON.parse(ci.ciAttributes.outputs)
logstash_outputs = "#{outputs.join("\n")}"

config = "input { \n #{logstash_inputs}   } \n " +
          "filter { \n #{logstash_filters} } \n" +
          "output { \n #{logstash_outputs } }" 
          
`mkdir -p /etc/logstash/`          
File.open("/etc/logstash/logstash.conf", 'w') {|f| f.write(config) } 

template "/etc/init.d/logstash" do
  source "initd.erb"
  owner "root"
  group "root"
  mode 0700
end

cookbook_file '/opt/nagios/libexec/check_logstash' do
  source 'check_logstash.rb'
  owner 'root'
  group 'root'
  mode 0755
end
     
# ensure the service is running
service 'logstash' do
  action :start
end          
