#
# netscaler::upload_cert_key - scp's the cert and key
#

require 'net/scp'

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }

if certs.nil? || certs.size==0
  Chef::Log.info("no certs in DependsOn payload")
  return
end

ci = certs.first

# uses lb cloud service
cloud_name = node[:workorder][:cloud][:ciName]
cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
Chef::Log.info("upload netscaler: #{node.netscaler_host}")

# write cert content to tmp file
cert_file = "oo-cert-"+ci[:ciId].to_s+".cer"
tmp_cert_file = "/tmp/"+cert_file
ns_cert_file = "/nsconfig/ssl/"+cert_file
node.set["ns_cert_file"] = cert_file

::File.open(tmp_cert_file, 'w') { |file| file.write(ci[:ciAttributes][:cert].gsub("\C-M","")) }

# write ca cert content to tmp file
if ci[:ciAttributes].has_key?("cacertkey") &&
   !ci[:ciAttributes][:cacertkey].empty?
  ca_cert_file = "oo-ca-cert-"+ci[:ciId].to_s+".cer"
  tmp_ca_cert_file = "/tmp/"+ca_cert_file
  ns_ca_cert_file = "/nsconfig/ssl/"+ca_cert_file
  node.set["ns_ca_cert_file"] = ca_cert_file
  node.set["ns_ca_cert_name"] = ca_cert_file.gsub(".cer","")
  
  ::File.open(tmp_ca_cert_file, 'w') { |file| file.write(ci[:ciAttributes][:cacertkey].gsub("\C-M","")) }
end

# write key content to tmp file
key_file = "oo-key-"+ci[:ciId].to_s+".key"
tmp_key_file = "/tmp/"+key_file
ns_key_file = "/nsconfig/ssl/"+key_file
node.set["ns_key_file"] = key_file

::File.open(tmp_key_file, 'w') { |file| file.write(ci[:ciAttributes][:key].gsub("\C-M","")) }

# verify using openssl
cmd = "openssl rsa -in #{tmp_key_file} -passin pass:'#{node.cert[:passphrase]}'"
result = `#{cmd}`
if $?.to_i != 0
  msg = "password does not decrypt private key"
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e  
end

# Fix for non-absolute home
ENV['HOME'] = '/tmp'

# upload files
# use a persistent connection to transfer files
# empty keys needed or else will prompt 
Net::SCP.start(
 node.netscaler_host, 
 cloud_service[:username], 
 :password => cloud_service[:password],
 :keys => []) do |scp|
 
  Chef::Log.info("key: #{tmp_key_file} to  #{ns_key_file}")
  scp.upload! tmp_key_file, ns_key_file

  Chef::Log.info("cert: #{tmp_cert_file} to #{ns_cert_file} ")
  scp.upload! tmp_cert_file, ns_cert_file

  if !ns_ca_cert_file.nil?
    Chef::Log.info("ca cert: #{tmp_ca_cert_file} to #{ns_ca_cert_file} ")
    scp.upload! tmp_ca_cert_file, ns_ca_cert_file
  end
end


# cleanup
::File.delete(tmp_key_file)
::File.delete(tmp_cert_file)
if !ns_ca_cert_file.nil?
  ::File.delete(tmp_ca_cert_file)
end
