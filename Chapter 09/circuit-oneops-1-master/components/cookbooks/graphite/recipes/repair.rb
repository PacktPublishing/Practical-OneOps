cookbook_name = node.app_name.downcase

Chef::Log.warn("Repair #{cookbook_name} is not implemented. Please use Start and Stop to restart Graphite services")
