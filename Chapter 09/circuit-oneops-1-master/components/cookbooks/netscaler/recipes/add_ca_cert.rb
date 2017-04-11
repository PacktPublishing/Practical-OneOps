#
# netscaler::add_cert_key - adds a sslcertkey ns object to be bound with a lbvserver
#

if !node.has_key?("ns_ca_cert_name")
  return
end

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

cert_key = {
  :certkey => node.ns_ca_cert_name,
  :cert => node.ns_ca_cert_file
}
Chef::Log.info("CA CERT: "+cert_key.inspect)

resp_obj = JSON.parse(node.ns_conn.request(
  :method=>:get, 
  :path=>"/nitro/v1/config/sslcertkey/#{node.ns_ca_cert_name}").body)        

  
req = nil
path = "/nitro/v1/config/sslcertkey/"

# new
if resp_obj["message"] =~ /Certificate does not exist/
  method = :post
  req = URI::encode('object= { "sslcertkey":'+JSON.dump(cert_key)+'}')

  resp_obj = JSON.parse(node.ns_conn.request(
    :method=> method,
    :path=> path, 
    :body => req).body)
    
  if resp_obj["errorcode"] != 0 &&
     resp_obj["errorcode"] != 273
      
    Chef::Log.error( "#{method} #{node.ns_ca_cert_name} resp: #{resp_obj.inspect}")    
    exit 1      
  else
    if resp_obj["errorcode"] == 273
  
      if resp_obj["message"] =~ /certkeyName Contents, (.*?)\]/
        node.set["ns_ca_cert_name"] = $1
        Chef::Log.info("using existing cert with name: #{node.ns_ca_cert_name}")
      end
    end

    Chef::Log.info( "#{method} #{node.ns_ca_cert_name} resp: #{resp_obj.inspect}")
  end 

else
  Chef::Log.info( "certkey #{node.ns_ca_cert_name} exists, updating with same values to handle update")  
  Chef::Log.info("using ssh and netscaler cli for sslcertkey because api doesnt support update fully")

  cloud_name = node[:workorder][:cloud][:ciName]
  if node[:workorder][:services].has_key?(:lb)
    cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
  else
    cloud_service = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
  end
  
  ENV['HOME'] = '/tmp'
  require 'net/ssh'
  ssh = Net::SSH.start(cloud_service[:host], cloud_service[:username],
                       :password => cloud_service[:password], :paranoid => Net::SSH::Verifiers::Null.new)

  cmd = "update ssl certKey #{node.ns_ca_cert_name} -cert #{node.ns_ca_cert_file} "
  cmd += "-noDomainCheck"
  Chef::Log.info("run: "+cmd)
  res = ssh.exec!(cmd)
  ssh.close
  Chef::Log.info("result: "+res)

  if res =~ /certkeyName Contents, (.*?)\]/
    node.set["ns_ca_cert_name"] = $1
    Chef::Log.info("using existing cert with name: #{node.ns_ca_cert_name}")
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
