#
# f5-bigip::f5_add_cert_key - adds a sslcertkey ns object to be bound with a lbvserver
#

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/}

if certs.nil? || certs.size==0
  Chef::Log.info("no certs in DependsOn payload")
  return
end

has_ssl = false
lbs = [] + node.loadbalancers + node.dcloadbalancers
lbs.each do |lb|
  #next if lb["vprotocol"] != "SSL" || "HTTPS"
  next if lb["vprotocol"] != "HTTPS"
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

include_recipe "f5-bigip::get_cert_name" # ==> node.set["cert_name"] = cert_name
include_recipe "f5-bigip::upload_cert_key"
#Sinclude_recipe "f5-bigip::add_ca_cert"

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

#passphrase = node.cert[:passphrase].gsub("@","\\x40").gsub("?","\\x3f").gsub("&","\\x26")
passphrase = node.cert[:passphrase]

cert_key = {
  :certkey => node.cert_name,
  :cert => node.ns_cert_file,
  :key => node.ns_key_file,
  :passplain => passphrase
}


f5_ltm_sslprofiles  "#{node.cert_name}" do
  f5  "#{node.f5_host}"
  sslprofile_name "#{node.cert_name}"
  keyid "#{node.cert_name}.key"
  certid  "#{node.cert_name}.crt"
  passphrase  "#{passphrase}"
  notifies :run, "f5_config_sync[#{node.f5_host}]", :delayed
end
