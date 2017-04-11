# Cookbook Name:: keystore
# Recipe:: add
#
# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }

keystore_filename = node.workorder.rfcCi.ciAttributes.keystore_filename
keystore_password = node.workorder.rfcCi.ciAttributes.keystore_password

if keystore_password.nil? || keystore_password.empty?
  puts "***FAULT:FATAL=missing keystore password"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e    
end

Chef::Log.info("keystore file will be generated in : #{keystore_filename}")

dir = File.dirname(keystore_filename)
directory dir do
  action :create
  recursive true
end

execute "rm -fr #{keystore_filename}"

certs.each do |cert|
   #cert has string elements: cacertkey, passphrase, path, key, cert and boolean: pkcs12
   Chef::Log.info("keystore path will be: #{cert[:ciAttributes][:path]} ")
    
  if !cert[:ciAttributes][:cacertkey].nil? && 
     !cert[:ciAttributes][:cacertkey].empty?

    tmp_ca = "/tmp/"+ (0..16).to_a.map{|a| rand(16).to_s(16)}.join + ".crt"
    
    File.open(tmp_ca, 'w') { |file| file.write(cert[:ciAttributes][:cacertkey]) }
      
      
    tmp_ce = "/tmp/"+ (0..16).to_a.map{|a| rand(16).to_s(16)}.join + ".crt"
      
    File.open(tmp_ce, 'w') { |file| file.write(cert[:ciAttributes][:cert]) }
      

    tmp_ck = "/tmp/"+ (0..16).to_a.map{|a| rand(16).to_s(16)}.join + ".key"
      
    File.open(tmp_ck, 'w') { |file| file.write(cert[:ciAttributes][:key]) }
     
    # First convert to an intermediate PKCS12 format
    cmd1 = "openssl pkcs12 -export -in #{tmp_ce} -inkey #{tmp_ck} -out /tmp/intermediate.p12 -certfile #{tmp_ca} -passout pass:#{keystore_password} -passin pass:#{cert[:ciAttributes][:passphrase]}"

      #old cmd = "keytool -import -trustcacerts -alias root -file #{tmp_ca} -keystore #{keystore_filename} -storepass #{keystore_password} >> /tmp/keytool.txt"
      
    execute "#{cmd1}" do
      returns [0]
    end
    
    # Then convert the PKCS12 into JKS storepass
    cmd2 = "keytool -importkeystore -srcstoretype PKCS12 -srckeystore /tmp/intermediate.p12 -srcstorepass #{keystore_password} -destkeystore #{keystore_filename} -deststorepass #{keystore_password}"
                   
    execute "#{cmd2}" do
     returns [0]
    end
                   
    # List out the certs to ensure it looks fine – has the private key as well as the CA chain
    cmd3 = "keytool -v -list -keystore #{keystore_filename} -storepass #{keystore_password} >> /tmp/keylist.txt"
      execute "#{cmd3}" do
      returns [0]
    end
      
      execute "rm -fr #{tmp_ca}"   
      execute "rm -fr #{tmp_ce}"
      execute "rm -fr #{tmp_ck}"
    
  end
end
