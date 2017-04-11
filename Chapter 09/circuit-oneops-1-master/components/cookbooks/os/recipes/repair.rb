
monitoring_enabled = true

ruby_block 'repair node' do
  block do
  
  if node.workorder["payLoad"].has_key?("Environment") &&
     node.workorder.payLoad.Environment[0][:ciAttributes].has_key?("monitoring") &&
     node.workorder.payLoad.Environment[0][:ciAttributes][:monitoring] == "false"
    
    monitoring_enabled = false
  end  
  
  if monitoring_enabled
    puts "***TAG:repair=agentrestart"
    run_context.include_recipe("os::repair_agent")
  else
    Chef::Log.info("not repairing perf-agent because environment.monitoring=false")        
    puts "***TAG:repair=norepairmonitoringdisabled"  
  end
 
 end
end


