# included via os::add
Chef::Log.info("Installing logstash-forwarder...")

#Setting variables
is_windows =  (node[:platform].downcase =~ /windows/)
destination = "#{node[:workorder][:cloud][:ciName]}.collector.#{node[:mgmt_domain].strip}:5000"
cert_path = "/etc/logstash/cert/perf-agent-lsf.crt"
root_user = 'root'
root_group = 'root'
exe_file = 'logstash-forwarder'
if is_windows
  root_user = 'Administrator'
  root_group = 'Administrators'
  exe_file = 'logstash-forwarder.exe'
end

#Determine if service already exists, do not check systemd service as we can modify it without disabling
service_exists = false
if is_windows
  service_exists = ::Win32::Service.exists?("perf-agent")
else
  service_exists =  File.exists?("/etc/init.d/perf-agent")
end

service "perf-agent" do
  action [ :stop, :disable ]
  only_if { service_exists && node['platform'] != 'ubuntu' }
end

#to stop and disable old flume agent
if File.exists?("/etc/init.d/perf-agent") && !is_windows

  link "/etc/init.d/perf-agent" do
    action :delete
    only_if "test -L /etc/init.d/perf-agent"
  end

  #delete the initd service because we are going to create a systemd service
  file '/etc/init.d/perf-agent' do
    action :delete
  end
end


#Create sub directories
['/etc/logstash/cert', '/etc/logstash/conf.d', '/etc/logstash-forwarder', '/opt/logstash-forwarder/bin'].each do |dir_name|
  directory dir_name do
    recursive true
  end
end

# Create the certificate file issued by Logstash so LSF can connect to Logstash service
file cert_path do
  content node[:perf_collector_cert]
end

#Create LSF config file
template "/etc/logstash-forwarder/perf-agent-lsf.conf" do
  cookbook 'os'
  source "logstash-forwarder.conf.erb"
  mode 0640
  variables({
    :destination => destination,
    :cert_path=> cert_path,
    :ip => node[:ipaddress]
  })
  owner root_user
  group root_group
end

#Get LSF executable from cookbook
cookbook_file "/opt/logstash-forwarder/bin/#{exe_file}" do
  cookbook 'os'
  source exe_file
  owner root_user
  group root_group
  mode 0700
end

#Install service from template, for linux only, in systemd if it's there, otherwise use init.d
template_name = '/etc/init.d/perf-agent'
source_name = 'lsf-initd.erb'
if File.directory?("/usr/lib/systemd/system")
  template_name = '/usr/lib/systemd/system/perf-agent.service'
  source_name = 'perf-agent-service.erb'
end

template template_name do
  cookbook 'os'
  source source_name
  variables({
    :log_dir => "/opt/oneops/log"
  })
  owner root_user
  group root_group
  mode 0700
  not_if {is_windows}
end
  
#Install service for windows  
if is_windows
  powershell_script 'Install service' do
    code "C:/Cygwin64/bin/cygrunsrv.exe -I perf-agent -p /opt/logstash-forwarder/bin/#{exe_file} -a '-config=/etc/logstash-forwarder/perf-agent-lsf.conf -spool-size 20'"
    not_if {service_exists}
  end
end
  
#ensure the service is running
service 'perf-agent' do
  action [ :enable, :restart ]
end


#Add a new conf file for rsyslog and restart it, only for linux VMs
template "/etc/rsyslog.d/oneops-perf-agent.conf" do
  cookbook 'os'
  source "log-conf.erb"
  owner root_user
  group root_group
  mode 0700
  not_if {is_windows}
end

service 'rsyslog' do
  action [ :restart ]
  not_if {is_windows}
end
