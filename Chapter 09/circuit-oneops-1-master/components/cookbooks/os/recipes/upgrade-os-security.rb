#
# Cookbook Name:: os
# Recipe:: upgrade-os-security
#


if node.platform? "ubuntu"

  upgrade_cmd = "grep \"-security\" /etc/apt/sources.list > /tmp/security.sources.list; "
  upgrade_cmd += "sudo apt-get -y upgrade -o Dir::Etc::SourceList=/tmp/security.sources.list"

  cmd = "apt-get -y update; DEBIAN_FRONTEND=noninteractive #{upgrade_cmd}"
else
  cmd = "yum -y update bash && yum -y install yum-security || true && yum -y update --security"
  
end  

Chef::Log.info("Updating bash and security packages.")
execute cmd

cur_tag = JSON.parse(node.workorder.ci["ciAttributes"]["tags"])

##Tag the current time-stamp.
cur_ts = Time.now.utc.iso8601
tags = {
  "security"=> cur_ts 
  }

puts "***RESULT:tags="+JSON.dump(cur_tag.merge(tags))
