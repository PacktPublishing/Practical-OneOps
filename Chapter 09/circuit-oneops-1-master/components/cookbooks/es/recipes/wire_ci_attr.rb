# Get all component attributes
ci = node.workorder.rfcCi.ciAttributes
Chef::Log.info("Wiring OneOps ElasticSearch ci attributes : #{ci.to_json}")

@cloud_name = node.workorder.cloud.ciName
@cookbook_name = node.app_name.downcase

# === VERSION AND LOCATION
#
node.set[:elasticsearch][:version]       = ci["version"]
node.set[:elasticsearch][:repository]    = "elasticsearch/#{node.elasticsearch[:version]}"
node.set[:elasticsearch][:filename]      = "elasticsearch-#{node.elasticsearch[:version]}.tar.gz"

# Search for component mirror
comp_mirrors = JSON.parse(ci["mirrors"])
base_url = ''
base_url = comp_mirrors[0] if !comp_mirrors.empty?
# Search for cloud mirror if no mirrors added
if base_url.empty?
  cloud_mirrors = JSON.parse(node[:workorder][:services][:mirror][@cloud_name][:ciAttributes][:mirrors])
  base_url = cloud_mirrors[@cookbook_name] if !cloud_mirrors.nil? && cloud_mirrors.has_key?(@cookbook_name)
end

# If URL not found in cloud/comp mirrors use defaults
if base_url.empty? 
  node.set[:elasticsearch][:repository]    = "elasticsearch/elasticsearch"
  node.set[:elasticsearch][:download_url]  = [node.elasticsearch[:host], node.elasticsearch[:repository], node.elasticsearch[:filename]].join('/')  
else
  node.set[:elasticsearch][:download_url]  = [base_url, node.elasticsearch[:repository], node.elasticsearch[:filename]].join('/')
  node.set[:elasticsearch][:base_url] = base_url
end

# === CLUSTER
#
node.set[:elasticsearch][:cluster][:name] = ci["cluster_name"]

if node[:elasticsearch][:version].start_with?("2")
  node.set[:elasticsearch][:network][:host] = node[:ipaddress]
end

# === INDEX
#
node.set[:elasticsearch][:index][:number_of_shards]    = ci["shards"]
node.set[:elasticsearch][:index][:number_of_replicas]    = ci["replicas"]

# === MEMORY
#
# Maximum amount of memory to use is automatically computed as one half of total available memory on the machine.
# You may choose to set it in your node/role configuration instead.
#
allocated_memory = "#{(node.memory.total.to_i * 0.6 ).floor / 1024}m"
node.set[:elasticsearch][:allocated_memory] = ci['memory'].to_s.strip.to_s.empty?() ? allocated_memory : ((ci['memory'].end_with? "m") ? ci['memory'] : ci['memory'] +"m")

# === PORT
#
node.set[:elasticsearch][:http][:port] = ci["http_port"]


# === USER & PATHS
#
node.set[:elasticsearch][:dir]       = ci["install_dir"]
node.set[:elasticsearch][:path][:conf] = ci["conf_dir"]
node.set[:elasticsearch][:path][:data] = ci["data_dir"]
node.set[:elasticsearch][:path][:logs] = ci["log_dir"]
node.set[:elasticsearch][:pid_path]  = ci["pid_file_path"]
node.set[:elasticsearch][:pid_file]  = "#{node.elasticsearch[:pid_path]}/#{node.elasticsearch[:node][:name].to_s.gsub(/\W/, '_')}.pid"

# === GATEWAY
#
if(!(ci["recover_after_nodes"].nil? || ci["recover_after_nodes"].empty?))
  node.set[:elasticsearch][:gateway][:recover_after_nodes] = ci["recover_after_nodes"]
end
if(!(ci["recover_after_time"].nil? || ci["recover_after_time"].empty?))  
  node.set[:elasticsearch][:gateway][:recover_after_time] = ci["recover_after_time"]
end
if(!(ci["expected_nodes"].nil? || ci["expected_nodes"].empty?))  
  node.set[:elasticsearch][:gateway][:expected_nodes] = ci["expected_nodes"]
end  

# ====NODE
#
node.set[:elasticsearch][:node][:master] = ci["master"]
node.set[:elasticsearch][:node][:data] = ci["data"]

# ====CUSTOM
#
if(!JSON.parse(ci["custom_config"]).empty?)
  node.set[:elasticsearch][:custom_config] = JSON.parse(ci["custom_config"])
end  
