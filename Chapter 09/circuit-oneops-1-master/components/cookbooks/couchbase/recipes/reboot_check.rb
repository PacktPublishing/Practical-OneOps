include_recipe "couchbase::port_wait"

reboot_flag = false

ruby_block 'reboot check' do
  block do
    if node.couchbase_port_closed
      if node.workorder.arglist.to_i >= 9
        reboot_flag = true
      else
        Chef::Log.info("Skipping reboot until retry is 10, work order retry count is #{ node.workorder.arglist.to_i + 1 }")
      end
    else
      Chef::Log.info("skipping because couchbase ports 8091 or 11210 are accessible")
      puts "***TAG:repair=skiphardrebootcouchbaseportsopen"
    end
    node.set[:allow_reboot] = reboot_flag
  end
end
