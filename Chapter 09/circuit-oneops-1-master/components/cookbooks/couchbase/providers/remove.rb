##
# process provider
#
# Interacts with couchbase process
#
# @Author Scott Boring - sboring@walmartlabs.com
##

def whyrun_supported?
  true
end

use_inline_resources


def rebalance(cluster_ip)

  if isCouchbaseRunning
    command = "/opt/couchbase/bin/couchbase-cli rebalance"
    command += " -c #{cluster_ip}:8091 "
    command += " -u #{new_resource.username}"
    command += " -p #{new_resource.password}"
    command += " --server-remove=#{new_resource.node}:8091"
    result = `#{command}`

    Chef::Log.info result
  end
end

def killCouchbase

  ps = `ps -u couchbase | grep beam | cut -d' ' -f1`
  ps.each { |p|
    `sudo kill -9 #{p}` }

end

def isCouchbaseRunning
  running = false
  is_couchbase_running = `sudo /etc/init.d/couchbase-server status | cut -d' ' -f3`
  if is_couchbase_running.include? "running"
    running = true
  end
  running
end

def removeCouchbase(node_platform)
  if isCouchbaseRunning
    ip_address = %x( hostname -i ).strip!
    Chef::Application.fatal!("Unable to stop couchbase for host: #{ip_address}")
  end

  dl_file = `sudo rpm -qa | grep couchbase-server`
  dl_file = dl_file.strip!

  #version = `sudo rpm -qa | grep couchbase-server |  cut -d- -f3-3`
  #determine platform type
  case node_platform
    # Redhat based distros
    when 'redhat', 'centos', 'fedora'
      pkg_type = 'rpm'
    # Debian based ditros
    when 'ubuntu', 'debian'
      pkg_type = 'deb'
    else
      Chef::Application.fatal!("#{node_platform} platform is not supported for Couchbase.")
  end


  if dl_file != nil
    Chef::Log.info "removing couchbase " + dl_file

    # Remove the package
    case pkg_type
      when 'rpm'
        `sudo rpm -e #{dl_file}`
      when 'deb'
        `sudo dpkg -r #{dl_file}`
    end
  end
end

def getActiveNode
  cluster_ip = "localhost"

  cli_nodes = `/opt/couchbase/bin/couchbase-cli server-list -c localhost:8091 -u #{new_resource.username} -p #{new_resource.password}`
  if cli_nodes != nil
    cli_nodes = cli_nodes.split("\n")
    if cli_nodes.size > 0
      cli_nodes.each { |x|
        data_node = x.split(" ")
        #Chef::Log.info data_node[1]
        if data_node != nil && data_node[2] == "healthy" && data_node[3] == "active"
          cluster_nodes = data_node[1].split(":")
          #Chef::Log.info cluster_nodes[0] + " VS " + new_resource.node
          if !(cluster_nodes[0].include? "#{new_resource.node}")
            cluster_ip = cluster_nodes[0]
            break
            end
        end
      }
    end
  end
  Chef::Log.info cluster_ip
  cluster_ip
end

def stopCouchbase
  `sudo sudo /etc/init.d/couchbase-server stop`
end

##
# Based on variable remove_action from recipe/delete.rb:
#  - If remove_action is remove_single_node then removes a node and rebalance.
#  - If remove_action is remove_cluster then removes each node in the cluster.
#  - If remove_action is remove_nothing. Fatal error. Only one node or entire cluster can be removed.
##

action :remove_single_node do
  #Chef::Application.fatal!("Implement remove action: #{new_resource.remove_action}")

  #Chef::Log.info "Removing " + new_resource.node + " from cluster " + new_resource.cluster

  cluster_ip = getActiveNode

  Chef::Log.info "Removing " + new_resource.node + " from cluster " + cluster_ip
  #Chef::Application.fatal!("STOP!")

  rebalance(cluster_ip)

  #wait for rebalance to finish
  sleep 30
  stopCouchbase
  if isCouchbaseRunning
    killCouchbase
  end
  removeCouchbase(new_resource.node_platform)

end

action :remove_cluster do
  stopCouchbase
  if isCouchbaseRunning
    killCouchbase
  end
  removeCouchbase(new_resource.node_platform)
end

action :remove_nothing do
  Chef::Application.fatal!("Unable to remove cluster or single node. Please remove only one node or decommission the cluster")
end
