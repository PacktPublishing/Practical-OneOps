
#Downlad nss-pam from nexus
attr=node.workorder.resultCi.ciAttributes

cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]

if services.nil?  || !services.has_key?(:ldap)
  exit_with_error "Please make sure your cloud has Service LDAP added."
end

cloud_services = services["ldap"][cloud_name]
ldap_uri =  Array.new(JSON.parse(cloud_services[:ciAttributes][:uri])).each { |uri| }.join(",")


pam_groupdn = '' 
if attr[:pam_groupdn]!=nil
  pam_groupdn =attr[:pam_groupdn]
end
  
  
Chef::Log.info("Installation start for pam_ldap")
 package "pam_ldap" do
    action :install
  end
Chef::Log.info("Installation done")  

Chef::Log.info("Installation start for nss-pam-ldapd")
package "nss-pam-ldapd" do
    action :install
 end
Chef::Log.info("Installation done")

# copy the nslcd
Chef::Log.info("Copy the nslcd")
template "/etc/nslcd.conf" do
  source "nslcd.conf.erb"
  mode "0600"
   variables({
    :uri => ldap_uri,
    :base => cloud_services[:ciAttributes][:base],
    :binddn => cloud_services[:ciAttributes][:binddn],
    :bindpw => cloud_services[:ciAttributes][:bindpw]
  })
  user "root"
  group "root"
end

#copy nss-ldap
Chef::Log.info("Copy the pam_ldap")
template "/etc/pam_ldap.conf" do
  source "pam_ldap.conf.erb"
  mode "0644"
   variables({
    :uri => ldap_uri,
    :base => cloud_services[:ciAttributes][:base],
    :binddn => cloud_services[:ciAttributes][:binddn],
    :bindpw => cloud_services[:ciAttributes][:bindpw],
    :pamfilter => "|" + cloud_services[:ciAttributes][:default_pam_groupdn]  +  pam_groupdn
  })
  user "root"
  group "root"
end

#nssservice
Chef::Log.info("Copy the nsservice")
template "/etc/nsswitch.conf" do
  source "nsswitch.conf.erb"
  mode "0644"
  variables({ :ldap => "ldap"})
  user "root"
  group "root"
end

# cp system-auth-ac and password-auth-ac
Chef::Log.info("Copy the password-auth-ac")
template "/etc/pam.d/password-auth-ac" do
  source "password-auth-ac.erb"
   variables(
     { :auth => "auth        sufficient    pam_ldap.so",
       :session => "session        sufficient    pam_ldap.so",
       :account => "account        sufficient    pam_ldap.so",
       :password => "password        sufficient    pam_ldap.so use_authtok"
     })
  mode "0644"
  user "root"
  group "root"
end

Chef::Log.info("Copy the system-auth-ac.erb")
template "/etc/pam.d/system-auth-ac" do
  source "system-auth-ac.erb"
  variables(
     { :auth => "auth        sufficient    pam_ldap.so",
       :session => "session        sufficient    pam_ldap.so",
       :account => "account        sufficient    pam_ldap.so",
       :password => "password        sufficient    pam_ldap.so use_authtok"
     })
  mode "0644"
  user "root"
  group "root"
end


Chef::Log.info("Copy the ldap.conf.erb")
template "/etc/openldap/ldap.conf" do
  source "ldap.conf.erb"
   variables({
    :uri => ldap_uri,
    :base => cloud_services[:ciAttributes][:binddn]
   }) 
  mode "0644"
  user "root"
  group "root"
end

Chef::Log.info("Restart the sshd service")
execute "sudo service sshd restart"


Chef::Log.info("Restart the nslcd service")
execute "sudo pkill -f '^/usr/sbin/nslcd -d' ; sudo service nslcd start"






