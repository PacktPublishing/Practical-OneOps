##
# cluster providers
#
# Initialize cluster
#
# @Author Alex Natale <anatale@walmartlabs.com>
##
require "net/http"

def whyrun_supported?
  true
end

use_inline_resources

def createSshKey
  # grab a secure key for ssh
  puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
  ssh_key_file = "/tmp/"+puuid

  file ssh_key_file do
    content new_resource.ssh_key
    mode 0600
  end

  ssh_key_file
end

def is_auto_failover_enabled

  response = nil

  Net::HTTP.start('localhost', new_resource.port) do |http|
    req = Net::HTTP::Get.new('/settings/autoFailover')
    req.basic_auth new_resource.username, new_resource.password
    response = http.request(req)
  end

  if ("200" == response.code)
    autoFailover = JSON.parse(response.body())

    if (!autoFailover.has_key?('enabled'))
      raise "COUCHBASE AUTO-FAILOVER ERROR: #{response.body()}"
    elsif (autoFailover['enabled'])
      return true
    else
      return false
    end
  else
    raise "Unable to connect to COUCHBASE server: #{response.code}"
  end

  return false
end

def executeOnAll(ssh_key_file, command)
  # now start each couchbase node
  new_resource.ips.each do |n|
    execWorkOrder = "sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{n[:ciAttributes][:private_ip]} #{command}"
    execute execWorkOrder
  end
end

def deleteSshKey(ssh_key_file)
  # clean up our ssh key
  file ssh_key_file do
    action :delete
  end
end

action :start_couchbase do
  ssh_key_file = createSshKey
  executeOnAll(ssh_key_file, "sudo /etc/init.d/couchbase-server start")
  deleteSshKey(ssh_key_file)
end

action :stop_couchbase do

  if(is_auto_failover_enabled)
    raise "Couchbase Auto-Failover is enabled. Auto-Failover must be disabled to STOP Couchbase Cluster."
  end
  ssh_key_file = createSshKey
  executeOnAll(ssh_key_file, "sudo /etc/init.d/couchbase-server stop")
  deleteSshKey(ssh_key_file)
end
