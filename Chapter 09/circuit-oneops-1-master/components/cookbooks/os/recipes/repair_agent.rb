#
# oo:repair_agent
#
ostype = node[:workorder][:ci][:ciAttributes][:ostype]

if ostype =~ /windows/
  #resync time with ntp server
  execute 'net start w32time & w32tm /resync /force'
  
  #Kill nagios and LSF, restart the services
  [ {:process => 'nagios', :service => 'nagios'},
    {:process => 'logstash-forwarder', :service => 'perf-agent'}].each do |a|
	
	powershell_script "hard-restart-#{a[:service]}" do
	  code = "./circuit-oneops-1/components/cookbooks/compute/files/default/service_hard_restart.ps1 -processName '#{a[:process]}' -serviceName '#{a[:service]}' "
	end
  end

  return
end

# repair nagios
execute "pkill -f '^/usr/sbin/nagios -d' ; /sbin/service nagios restart"

ruby_block 'repair agent' do
  block do
    
    # time
    if node[:workorder][:services].has_key?(:ntp)
      # ntpdate depricated ; ntpd -g runs standard now
      Chef::Log.info(`/sbin/service ntpd restart`)
    else
      Chef::Log.info("no ntp cloud service ; not running ntpd -g")
    end
        
    # restart agent
    agent_reset_stdout = `rm -fr /opt/flume/log ; /sbin/service perf-agent restart`
    Chef::Log.info(agent_reset_stdout)
    if agent_reset_stdout.include? "not starting because root is"
      puts "***TAG:repair=root_fs_full"
    elsif agent_reset_stdout.include? "java not found"
      puts "***TAG:repair=java_not_found"  
    end    
  
  end
end
