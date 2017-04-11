#
# Cookbook Name:: os
# Recipe:: upgrade-os-all
#

if node.platform? "ubuntu"
  upgrade_cmd = "sudo apt-get -o Dpkg::Options::='--force-confnew' --force-yes -fuy dist-upgrade"
  cmd = "apt-get -y update; DEBIAN_FRONTEND=noninteractive #{upgrade_cmd}"  
else
  cmd = "yum -y update"    
end  

execute cmd


