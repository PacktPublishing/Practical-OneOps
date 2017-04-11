#
# netscaler::add_cert_key - adds a sslcertkey ns object to be bound with a lbvserver
#

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/}

if certs.nil? || certs.size==0
  Chef::Log.info("no certs in DependsOn payload")
  return
end

has_ssl = false
lbs = [] + node.loadbalancers + node.dcloadbalancers
lbs.each do |lb|
  next if lb["vprotocol"] != "SSL"
  has_ssl = true
end

unless has_ssl
  Chef::Log.info("no SSL service_type - skipping cert upload")
  return
end


if certs.first[:rfcAction] == "delete" && node.workorder.rfcCi.rfcAction != "delete"
  msg = "Cannot delete the lb-certificate when an https listener is specified"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
    

node.set[:cert] = certs.first[:ciAttributes]

include_recipe "netscaler::get_cert_name"
include_recipe "netscaler::upload_cert_key"
include_recipe "netscaler::add_ca_cert"

#        private String certkey;
#        private String cert;
#        private String key;
#        private Boolean password;
#        private String fipskey;
#        private String inform;
#        private String passplain;
#        private String expirymonitor;
#        private Long notificationperiod;
#        private String linkcertkeyname;
#        private Boolean nodomaincheck;

# escape certain chars to prevent netscaler response: Invalid JSON input
passphrase = node.cert[:passphrase].gsub("@","\\x40").gsub("?","\\x3f").gsub("&","\\x26")

cert_key = {
  :certkey => node.cert_name,
  :cert => node.ns_cert_file,
  :key => node.ns_key_file,
  :passplain => passphrase
}


resp_obj = JSON.parse(node.ns_conn.request(
  :method=>:get, 
  :path=>"/nitro/v1/config/sslcertkey/#{node.cert_name}").body)        

  
req = nil
ssh = nil
path = "/nitro/v1/config/sslcertkey/"

# new
if resp_obj["message"] =~ /Certificate does not exist/
  method = :post
  req = URI::encode('object= { "sslcertkey":'+JSON.dump(cert_key)+'}')

  resp_obj = JSON.parse(node.ns_conn.request(
    :method=> method,
    :path=> path, 
    :body => req).body)
  
  if resp_obj["errorcode"] == 1614
    Chef::Log.error( "#{method} #{node.cert_name} resp: #{resp_obj.inspect}")
    message="Invalid Password for sslcertkey"
    Chef::Log.error( message )
    puts "***FAULT:FATAL="+message
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
    
  elsif resp_obj["errorcode"] != 0 &&
     resp_obj["errorcode"] != 273
      
    Chef::Log.error( "#{method} #{node.cert_name} resp: #{resp_obj.inspect}")    
    exit 1      
  else
    if resp_obj["errorcode"] == 273
  
      if resp_obj["message"] =~ /certkeyName Contents, (.*?)\]/
        node.set["cert_name"] = $1
        Chef::Log.info("using existing cert with name: #{node.cert_name}")
      end
    end

    Chef::Log.info( "#{method} #{node.cert_name} resp: #{resp_obj.inspect}")
  end 
  
  if node.has_key?("ns_ca_cert_name")
    cert_key["linkcertkeyname"] = node.ns_ca_cert_name
  end  

else
  Chef::Log.info( "certkey #{node.cert_name} exists, updating with same values to handle update")  
  Chef::Log.info("using ssh and netscaler cli for sslcertkey because api doesnt support update fully")

  cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key?(:lb)
    cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
  else
    cloud_service = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
  end
  
  ENV['HOME'] = '/tmp'
  require 'net/ssh'
  ssh = Net::SSH.start(node.netscaler_host, cloud_service[:username],
                       :password => cloud_service[:password], :paranoid => Net::SSH::Verifiers::Null.new)

  cmd = "update ssl certKey #{node.cert_name} -cert #{node.ns_cert_file} "
  cmd += "-key #{node.ns_key_file} "
  unless passphrase.nil? || passphrase.empty?
    cmd += "-password #{passphrase} "
  end
  cmd += "-noDomainCheck "
  Chef::Log.info("run: "+cmd)
  res = ssh.exec!(cmd)



  Chef::Log.info("result: "+res)

  if res =~ /certkeyName Contents, (.*?)\]/
    node.set["cert_name"] = $1
    Chef::Log.info("using existing cert with name: #{node.cert_name}")
  end  
  
  if !res.include?("Done")
    message="update ssl certKey returned: "+res
    Chef::Log.error( message )
    puts "***FAULT:FATAL="+message
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e    
  end

    
end


if node.has_key?("ns_ca_cert_name")
  if ssh.nil?
    cloud_name = node[:workorder][:cloud][:ciName]
    cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
    
    ENV['HOME'] = '/tmp'
    require 'net/ssh'
    ssh = Net::SSH.start(node.netscaler_host, cloud_service[:username],
                         :password => cloud_service[:password], :paranoid => Net::SSH::Verifiers::Null.new)
  end

  cmd = "link ssl certKey #{node.cert_name} #{node.ns_ca_cert_name} "
  Chef::Log.info("run: "+cmd)
  res = ssh.exec!(cmd)

  Chef::Log.info("result: "+res)
  
  if !res.include?("Done")
    if (res.include?("ERROR") && !res.include?("Resource already exists"))
      message="link ssl certKey #{node.cert_name} #{node.ns_ca_cert_name} ...returned: "+res
      Chef::Log.error( message )
      puts "***FAULT:FATAL="+message
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e    
    end
  end
end

if !ssh.nil?
  ssh.close
end


lbs = [] + node.loadbalancers + node.dcloadbalancers
lbs.each do |lb|

  next if lb[:vprotocol] != "SSL"
  
  
  binding = { :vservername => lb[:name], :certkeyname => node.cert_name }    
  
  Chef::Log.info("binding: #{binding.inspect}")
  
  req = 'object= { "sslvserver_binding" : '+JSON.dump(binding)+ '}'
    
  resp_obj = JSON.parse(node.ns_conn.request(
    :method=>:post, 
    :path=>"/nitro/v1/config/sslvserver_sslcertkey_binding/#{lb[:name]}?action=bind", 
    :body => URI::encode(req)).body)
  
  if resp_obj["errorcode"] != 0
    Chef::Log.error( "post bind #{node.cert_name} resp: #{resp_obj.inspect}")
    exit 1      
  else
    Chef::Log.info( "post bind #{node.cert_name} resp: #{resp_obj.inspect}")
  end

end  
