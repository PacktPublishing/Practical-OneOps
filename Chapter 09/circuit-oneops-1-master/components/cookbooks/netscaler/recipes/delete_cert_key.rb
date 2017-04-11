#
# adds a monitor which will be binded to service in add_services
#

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/}

if certs.nil? || certs.size==0
  Chef::Log.info("no certs in DependsOn payload")
  return
end

n = netscaler_connection "conn" do
  action :nothing
end
n.run_action(:create)

include_recipe "netscaler::get_cert_name"

resp_obj = JSON.parse(node.ns_conn.request(
  :method=>:get, 
  :path=>"/nitro/v1/config/sslcertkey/#{node.cert_name}").body)        


node.set[:cert] = certs.first[:ciAttributes]

#cert_key = {
#  :certkey => node.cert_name,
#  :cert => node.ns_cert_file,
#  :key => node.ns_key_file,
#  :passplain => node.cert[:passphrase]
#}

#Chef::Log.info(cert_key.inspect)

req = nil
method = :delete
if resp_obj["message"] !~ /Certificate does not exist/  
  path = "/nitro/v1/config/sslcertkey/#{node.cert_name}"
else
  Chef::Log.info( "certkey #{node.cert_name} already deleted.")    
  # update accomplished via upload_cert_key (content) changes
  return
end

resp_obj = JSON.parse(node.ns_conn.request(
  :method=> method,
  :path=> path).body)

if resp_obj["errorcode"] == 1541
  Chef::Log.error( "still in use, cannot delete")
  Chef::Log.error( "#{method} ssl cert: #{node.cert_name} resp: #{resp_obj.inspect}")

elsif resp_obj["errorcode"] != 0     
  Chef::Log.error( "#{method} ssl cert: #{node.cert_name} resp: #{resp_obj.inspect}")    
  exit 1      
else
  Chef::Log.info( "#{method} ssl cert: #{node.cert_name} resp: #{resp_obj.inspect}")
end 
