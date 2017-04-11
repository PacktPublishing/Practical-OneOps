nodes = node.workorder.payLoad.ManagedVia
port = 6379
#if node.platform =~ /redhat|centos/
redisio_bin = "/usr/local/bin"
redisio_trib = "#{redisio_bin}/redis-trib.rb"

nodes.each do |compute|
        ip = compute[:ciAttributes][:private_ip]
        puts ip
end

ruby_block 'Fix REDIS  Cluster' do
        block do
                cln = `redis-cli cluster info |grep cluster_known_nodes| awk -F: '{print $2}'`.chomp
                Chef::Log.info("cluser nodes  #{cln}")
                wip = `redis-cli cluster nodes |grep -v fail`.split[1]
                Chef::Log.info("Woring IP's  #{wip}")
                fip = `redis-cli cluster nodes |grep fail`.split
                Chef::Log.info("FAILED IP's  #{fip}")
                if cln.include?('1')
                run_context.include_recipe "ring::add"
                elsif !fip.nil?
                        fip.each do |fip|
                        add_node_cmd = "#{redisio_trib} add -node #{fip} #{wip[0]}"
                        Chef::Log.info("Add node CMD  #{add_node_cmd}")
                        add_node = `#{add_node_cmd}`
                        end
                elsif fip.nil?
                puts "NO FAILED NODES"
                else
                Chef::Log.info('Please rebuild the REDIS Cluster')
                end
        end
end

#dns_record used for fqdn
dns_record = ""
nodes.each do |n|
  if dns_record == ''
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ',' + n[:ciAttributes][:dns_record]
  end
end

puts "***RESULT:dns_record=#{dns_record}"
