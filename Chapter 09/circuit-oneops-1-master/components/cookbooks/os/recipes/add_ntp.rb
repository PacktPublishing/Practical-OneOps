
if node.cloud_provider =~ /azure/
  package "ntp" do
    action :install
  end
end

cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
if services.nil?  || !services.has_key?(:ntp)
  exit_with_error "Please make sure your cloud has NTP service added."
end

ntp_service = services["ntp"][cloud_name]
ntpservers = JSON.parse(ntp_service[:ciAttributes][:servers])

Chef::Log.info("Configuring and enabling NTP")
if node['platform'] == 'windows'

  service 'w32time' do
    action [ :enable, :start ] 
  end
  
  execute 'set-ntp-server' do
    command "w32tm /config /manualpeerlist:\"#{ntpservers.collect {|x| x + ",0x09" }.join(" ")}\" /syncfromflags:MANUAL /reliable:yes /update & w32tm /resync /force"
  end
  
else
  template "/etc/ntp.conf" do
    source "ntp.conf.erb"
    mode "0600"
     variables({
      :ntpservers => ntpservers
    })
    user "root"
    group "root"
  end
  
  service "ntpd" do
    case node['platform']
    when 'centos','redhat','fedora'
      service_name 'ntpd'
    else
      service_name 'ntp'
    end
    action [ :enable, :start ]
  end

  ruby_block "Query NTP" do
    block do
      ntpstatus = `ntpq -p`
      Chef::Log.info("ntpq -p\n#{ntpstatus}")
    end
  end
end

