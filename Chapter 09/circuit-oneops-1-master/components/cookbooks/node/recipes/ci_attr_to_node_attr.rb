#
# Cookbook Name:: node
# Recipe:: add
#

ci = node.workorder.rfcCi.ciAttributes
Chef::Log.info("Wiring OneOps CI attributes : #{ci.to_json}")


# Global attributes
node.set[:nodejs][:install_method] = ci['install_method']
node.set[:nodejs][:version] = ci['version']
node.set[:nodejs][:src_url] = ci['src_url']
# Instance attributes
node.set[:nodejs][:dir] = ci['dir']
node.set[:nodejs][:npm] = ci['npm']
node.set[:nodejs][:npm_src_url] = ci['npm_src_url']
node.set[:nodejs][:check_sha] = ci['check_sha']

if node.nodejs.src_url.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  else
    exit_with_error "Cloud Mirror Service has not been defined"
  end
  node.set[:nodejs][:src_url] = mirrors["nodejs"]
  if node.nodejs.src_url.nil?
    exit_with_error "nodejs source repository has not beed defined in cloud mirror service"
  else
    Chef::Log.info("nodejs source repository has been defined in cloud mirror service #{node.nodejs.src_url}")
  end
else
  node.set[:nodejs][:src_url] = node.nodejs.src_url
end
