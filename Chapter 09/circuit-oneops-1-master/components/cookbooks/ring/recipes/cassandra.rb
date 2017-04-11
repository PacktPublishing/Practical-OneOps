dir=run_context.cookbook_collection["cassandra"].root_dir
Chef::Log.info dir
require "#{dir}/libraries/cassandra_util"
nodes = node.workorder.payLoad.ManagedVia

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

extra = ""
if ci['ciAttributes'].has_key?("extra")
  extra = ci['ciAttributes']['extra']
end

# dns_record used for fqdn
dns_record = ""

nodetool = "nodetool"
cassandra_bin = ""

if node.platform =~ /redhat|centos/
  cassandra_bin = "/opt/cassandra/bin"
  nodetool = "#{cassandra_bin}/nodetool"
end
nodes.each do |compute|
  ip = compute[:ciAttributes][:private_ip]

  next if ip.nil? || ip.empty?
  ruby_block "#{compute[:ciName]}_ring_join" do
    Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
    block do
      while(!cluster_normal?(node)) do
        Chef::Log.info("wait while node is moving/joining/leaving")
        sleep 5
      end

      cmd = "#{nodetool} -h #{ip} join 2>&1"
      Chef::Log.info(cmd)
      result  = `#{cmd}`
  
      if $? != 0
        Chef::Log.error(result)
        puts "***FAULT:FATAL="+result
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e         
      end
      
    end
    not_if "#{nodetool} -h #{ip} info 2> /dev/null"
  end

  if dns_record == ""
    dns_record = ip
  else
    dns_record += ","+ip
  end

end

puts "***RESULT:dns_record=#{dns_record}"



# keyspaces and other extra
unless extra.nil? || extra.empty?
  file "/tmp/cassandra-schema.txt" do
      owner "root"
      group "root"
      mode "0755"
      content "#{extra}"
      action :create
  end
  execute "extra" do
    command "#{cassandra_bin}cassandra-cli -host localhost -port 9160 -f /tmp/cassandra-schema.txt"
    action :run
    ignore_failure true
  end
end
