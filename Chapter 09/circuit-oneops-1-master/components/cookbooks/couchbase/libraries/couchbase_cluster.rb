module Couchbase
  class InvalidCredentialsError < StandardError
  end
  class CouchbaseCluster

    attr_reader :username, :password
    @cli
    @rest

    def initialize(ip, user, password)

      @username = user
      @password = password
      @cli=Couchbase::CouchbaseCLI.new(ip, user, password)
      @rest=Couchbase::CouchbaseREST.new(ip, user, password)
      begin
        list_buckets
      rescue Exception => e
        if e.message.include?("please check your username (-u) and password (-p)")
          raise InvalidCredentialsError, "Invalid Username/Password for Couchbase Cluster"
        else
          Chef::Log.error "NODE:#{ip} #{e.message}"
          raise e
        end
      end


    end

    def fail_over_node(outgoing_node_ip, port_number=8091, is_hard_failover = false)

      @cli.port_number = port_number
      @cli.fail_over_node(outgoing_node_ip, is_hard_failover)

    end

    def init(ramsize, port=8091)

      @cli.init_cluster(@username, @password, ramsize, port)

    end

    def details

      @rest.cluster_details

    end

    def rebalance(port_number=8091)

      @cli.port_number = port_number
      @cli.rebalance

    end

    def remove_node_with_rebalance(outgoing_node_ip, port_number=8091)

      # Validations
      # 1) fail if multiple nodes unhealthy
      # 2) fail if cluster is unhealthy, there's at least 1 bucket and the outgoing node is a healthy node.
      # This implies there is another unhealthy node and removing this node would result in data loss.

      raise 'ERROR: Cannot perform node removal and rebalance operation if multiple nodes are unhealthy' if (multiple_nodes_unhealthy?)
      if (!all_healthy? && list_buckets.length > 0 && node_healthy?(outgoing_node_ip))
        raise "ERROR: Removing healthy node #{outgoing_node_ip} and rebalancing while other node(s) are down may lead to data loss."
      end

      @cli.port_number = port_number
      @cli.remove_node(outgoing_node_ip)

    end

    def add_node(incoming_node_ip, port_number=8091)

      @cli.port_number = port_number
      @cli.add_node(incoming_node_ip)

    end

    def add_bucket(name, password, ramsize, replica)
      @cli.add_bucket(name, password, ramsize, replica)
    end

    def remove_bucket(name, password)
      @cli.remove_bucket(name, password)
    end

    def edit_bucket(name, password, ramsize, replica)
      @cli.edit_bucket(name, password, ramsize, replica)
    end

    def bucket_info(name)
      begin
        response=@rest.bucket_info(name)

        bucket_info=CouchbaseBucketInfo.new
        bucket_info.name=response.fetch("name")
        bucket_info.replica=response.fetch('replicaNumber')
        bucket_info.ram_quota=response.fetch('quota')['ram']
        bucket_info.nodes_size=response.fetch('nodes').size

      rescue Exception => e
        Chef::Log.error e.message
        raise "no bucket #{name} found"
      end
      bucket_info
    end

    def list_buckets

      list = @cli.list_buckets
      line_count = 0
      names = []

      list.each_line do |line|

        if line_count == 0
          names.push(line.tr("\n", ""))
        end

        line_count += 1
        line_count = line_count % 7
      end

      return names
    end

    def all_healthy?

      list = @cli.list_nodes

      list.each_line do |line|

        if line.split(' ')[2] != 'healthy'
          return false
        end
      end

      return true
    end

    def all_active?

      list = @cli.list_nodes

      list.each_line do |line|

        if line.split(' ')[3] != 'active'
          return false
        end
      end

      return true
    end

    def rebalance?

      @cli.rebalance_status.include?("running")
    end

    def list_servers

      list = @cli.list_nodes
      servers = []

      list.each_line do |line|
        servers.push(line.split(' ')[1])
      end

      return servers
    end

    def list_nodes_unhealthy
      response = @rest.cluster_details
      nodes = response['nodes']
      node_list = Array.new()

      nodes.each do |node|
        check_ip = node['hostname'].split(':')[0]
        node_status = node['status']
        if (node_status.eql?('unhealthy'))
          node_list.push("#{check_ip} #{node_status}")
        end
      end
      node_list
    end

    def list_nodes
      response = @rest.cluster_details
      nodes = response['nodes']
      node_list = Array.new()

      nodes.each do |node|
        ip = node['hostname'].split(':')[0]
        node_status = node['status']
        node_membership= node['clusterMembership']
        node_list.push({:ip => ip, :node_status => node_status, :node_membership => node_membership})

      end
      node_list
    end

    def list_node(ip_node)
      list_nodes.select { |node| node.fetch(:ip) == ip_node }
    end

    def healthy_nodes
      response = @rest.cluster_details
      nodes = response['nodes']
      healthy_nodes = 0

      nodes.each do |node|
        node_status = node['status']
        node_membership= node['clusterMembership']

        if (node_status.eql?('healthy') && node_membership.eql?('active'))
          healthy_nodes += 1
        end

      end
      healthy_nodes
    end

    def failover_nodes
      response = @rest.cluster_details
      nodes = response['nodes']
      failover_nodes = 0

      nodes.each do |node|
        node_membership= node['clusterMembership']

        if (node_membership.eql?('inactiveFailed'))
          failover_nodes += 1
        end

      end
      failover_nodes
    end

    def list_inactive_nodes
      response = @rest.cluster_details
      nodes = response['nodes']
      node_list = Array.new()

      nodes.each do |node|
        node_membership= node['clusterMembership']
        ip = node['hostname'].split(':')[0]

        if (node_membership.include?('inactive'))
          node_list.push({:ip => ip, :node_membership => node_membership})
        end

      end
      node_list
    end

    def server_readd

      ips = list_inactive_nodes.map { |node| node.fetch(:ip) }
      @cli.readd_nodes(ips)

    end

    def multiple_nodes_unhealthy?

      response = @rest.cluster_details
      nodes = response['nodes']
      unhealthy_counter = 0
      node_list = Array.new()

      nodes.each do |node|
        check_ip = node['hostname'].split(':')[0]
        node_status = node['status']
        node_list.push("#{check_ip} #{node_status} #{node['clusterMembership']}")
        if (node_status.eql?('unhealthy'))
          unhealthy_counter = unhealthy_counter + 1
        end
      end

      if (unhealthy_counter > 1)
        return true
      else
        return false
      end

    end

    def node_healthy?(node_ip)

      list = @cli.list_nodes

      list.each_line do |line|

        if line.split(' ')[1].split(':')[0].eql?(node_ip) && (!line.split(' ')[3].eql?('active'))
          return false
        end

      end

      return true

    end

    def autofailover_enabled?
      @rest.autofailover["enabled"]
    end

    def autofailover_timeout
      @rest.autofailover["timeout"]
    end

    def autofailover(enabled, timeout)
      @rest.set_autofailover(enabled, timeout)
    end

    # Logic from core-data.js
    def rebalance_needed?
      details = @rest.cluster_details
      is_rebalancing = details['rebalanceStatus'] != 'none'
      is_balanced = details['balanced']
      pending_servers = details['nodes'].select { |node| node['clusterMembership'] != 'active' }
      unhealthy_active = details['nodes'].select { |node| node['clusterMembership'] == 'active' && node['status'] == 'unhealthy' }.first

      recovery_task = @rest.tasks.select { |task| task['type'] == 'recovery' }.first

      return !is_rebalancing && (recovery_task == nil) && (pending_servers.length > 0 || !is_balanced) && (unhealthy_active == nil);
    end

    def need_reset_quota?
      results=@rest.autofailover

      status = results.fetch('count') == 0 ? false : true

      status
    end

    def reset_quota
      results = @rest.reset_quota
      results
    end
  end


  class CouchbaseBucketInfo

    attr_accessor :name, :replica, :ram_quota, :nodes_size


  end

end
