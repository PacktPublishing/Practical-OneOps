#
# Cookbook Name:: nodejs
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
node.set[:nodejs][:server] = ci['serverPath']
node.set[:nodejs][:options] = ci['options']
node.set[:nodejs][:script_location] = ci['script_location']
node.set[:nodejs][:as_user] = ci['as_user']
