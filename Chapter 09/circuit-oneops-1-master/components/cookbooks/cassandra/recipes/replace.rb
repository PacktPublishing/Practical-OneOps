# cassandra replace

ruby_block "replace_address option" do
  block do
    
    node.set["cassandra_replace_option"] = "-Dcassandra.replace_address=#{node.workorder.rfcCi.ciAttributes.node_ip}"
    
  end
end
 
include_recipe "cassandra::add"

#Remove cassandra.replace_address JVM option from cassandra-env.sh
availability_mode = node.workorder.box.ciAttributes.availability 
if availability_mode != "single"
  ruby_block "replace replace_address" do
    block do
      if node.has_key?("cassandra_replace_option") && !node.cassandra_replace_option.nil?
        bash_option = "JVM_OPTS=\\\"\\$JVM_OPTS #{node.cassandra_replace_option}\\\""
        cmd = "sed -i '/#{bash_option}/d' /opt/cassandra/conf/cassandra-env.sh"
        Chef::Log.info("starting using: #{cmd}")
        cmd_result = shell_out(cmd)
        cmd_result.error!
      end
    end
  end
end