nodes = node.workorder.payLoad.ManagedVia
nodes.each do |compute|
	ccheck = `redis-cli cluster info |grep cluster_state | cut -f2 -d ":"`
	ccheck = ccheck.delete("\r")
	ccheck = ccheck.delete("\n")
	puts ccheck
	if ccheck == "ok"
		puts "Cluster is running fine"
	else 
        	puts "Cluster is not running good repair cluster manually"
	end
end
