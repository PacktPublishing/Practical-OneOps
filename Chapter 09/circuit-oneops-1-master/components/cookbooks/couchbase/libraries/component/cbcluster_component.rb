module Couchbase
  module Component
    class ClusterException < Exception
    end
    class CbClusterComponent
      @data
      @cluster
      @port
      @username
      @password
      @env_profile
      @errors
      @nodes

      def initialize(data)
        @data = data
        @errors = []
        set_environment

        # cm is dynamic payload defined in the pack to get the resources
        if (@data.workorder.payLoad.has_key?('cm'))
          cm = @data.workorder.payLoad.cm.select { |c| c['ciClassName'].split('.').last == 'Couchbase' }.first

          attributes = cm["ciAttributes"]
          @username = attributes["adminuser"]
          @password = attributes["adminpassword"]
          @port = attributes["port"]

        else
          cb = @data.workorder.payLoad.DependsOn.select { |c| c['ciClassName'].split('.').last == 'Couchbase' }.first

          attributes = cb["ciAttributes"]
          @username = attributes["adminuser"]
          @password = attributes["adminpassword"]
          @port = attributes["port"]
        end

        @nodes=@data.workorder.payLoad.ManagedVia
        @nodes.each { |node|
          if node['ciAttributes'].has_key?("public_ip") && !node['ciAttributes']['public_ip'].empty?
            ip=node['ciAttributes']["public_ip"]
	  else
            ip=node['ciAttributes']["private_ip"]
	  end
          
	  begin
            @cluster = Couchbase::CouchbaseCluster.new(ip, @username, @password)
            if @cluster.list_nodes.length > 0
              break
            end
          rescue Exception => e
            Chef::Log.warn "NODE:#{ip} #{e.message}"
          end

        }

      end



      def set_environment
        env=@data.workorder.payLoad.has_key?('Environment') ? @data.workorder.payLoad.Environment.first : nil
        if (env !=nil && env.has_key?('ciAttributes') && env["ciAttributes"].has_key?("profile") && env["ciAttributes"]["profile"] == "dev")
          @env_profile=env["ciAttributes"]["profile"].downcase
        end
      end

      def execute

        @data.run_list.each { |action|
          if action.name == "cb_cluster::cluster-collect-logs"
            collect_cb_logs
          elsif action.name == "cb_cluster::cluster-health-check"
            cluster_health_check
          elsif action.name == "cb_cluster::autofailover-enable"
            autofailover_enable
          elsif action.name == "cb_cluster::autofailover-disable"
            autofailover_disable
          elsif action.name == "cb_cluster::cluster-repair"
            repair
          else
            Chef::Log.warn "unknown action #{action}"
          end
        }

      end

      def repair
        @errors = []
        run_rebalance
        reset_quota

        log_errors("Repair failed.")
      end

      def reset_quota
        if @cluster.need_reset_quota? && @cluster.all_healthy? && @cluster.all_active? && @nodes.size == @cluster.list_nodes.size && !@cluster.rebalance_needed?
          @cluster.reset_quota
        end

        if @cluster.need_reset_quota?
          if !@cluster.rebalance_needed?
            reset_cluster_manager
          end
          @errors.push("Unable to 'Reset Quota'. SEE: https://confluence.walmart.com/x/qI6-Bw")
        else
          Chef::Log.info("Quota was reset")
        end
      end

      def reset_cluster_manager_on_node(ip)
        `curl --data "erlang:halt()." -u #{@username}:#{@password} http://#{ip}:8091/diag/eval`
      end

      def loop_until_node_healthy(ip)
        cluster=nil
        begin
          Timeout::timeout(25) do
            reset_cluster_manager_on_node(ip)
            begin
              while cluster.nil? do
                begin
                  cluster=Couchbase::CouchbaseCluster.new(ip, @username, @password)
                rescue Exception => e
                  #puts "NODE:#{ip} #{e.message}"
                  sleep(2)
                  Chef::Log.info "Sleep 2 seconds before reconnection to node #{ip}"
                end
                #is_node_healthy=cluster.nil?
              end
            end while !(cluster.all_healthy? && cluster.all_active?)
          end
        rescue Timeout::Error
          Chef::Log.warn "Timeout. Unable to connect #{ip}"
        end
      end

      def reset_cluster_manager
        @nodes.each { |node|
          ip = node['ciAttributes']['private_ip']
          unless ip.nil?
            Chef::Log.info "Resetting cluster manager for ip:#{ip}"
            loop_until_node_healthy(ip)
          end
        }
      end


      def run_rebalance

        inactive_nodes = @cluster.list_inactive_nodes

        if @cluster.rebalance_needed? && @cluster.all_healthy? && @nodes.size == @cluster.list_nodes.size && inactive_nodes.size <= 1
          if inactive_nodes.size == 1
            Chef::Log.info("Adding node #{inactive_nodes.first.fetch(:ip)} back.")
            @cluster.server_readd
          end
          Chef::Log.info "Running Rebalance"
          @cluster.rebalance

          if @cluster.rebalance_needed?
            reset_cluster_manager
            @errors.push("Unable to Rebalance. SEE: https://confluence.walmart.com/x/qI6-Bw")
          end

        elsif @cluster.rebalance_needed? || !@cluster.all_healthy?
          #reason it fails to rebalance
          if @nodes.size != @cluster.list_nodes.size
            @errors.push("Cache Nodes mismatch OneOps Computes. SEE: https://confluence.walmart.com/x/qI6-Bw")
          end

          if @cluster.need_reset_quota?
            @errors.push("'Reset Quota' needs to be reset. SEE: https://confluence.walmart.com/x/qI6-Bw")
          end

          if inactive_nodes.size > 1
            @errors.push("More than one inactive node. SEE: https://confluence.walmart.com/x/qI6-Bw")
          end

          if !@cluster.all_healthy?
            @errors.push("One or more nodes are unhealthy. SEE: https://confluence.walmart.com/x/qI6-Bw")
          end

        else
          Chef::Log.info "Rebalance is not needed."
        end

      end

      def collect_cb_logs

        logs='Logs uploaded to https://s3.amazonaws.com/customers.couchbase.com/walmartlabs/ -'

        @nodes.each do |node|
          if node['ciAttributes'].has_key?("private_ip")
            logs += collect_cb_log(node['ciAttributes']["private_ip"]) + ' '
          end
        end
        Chef::Log.info logs
        if @env_profile=='dev'
          puts logs
        end

      end

      def collect_cb_log(node)

        data=Time.new.strftime("%F")
        filename="#{node.gsub('.', '_')}-#{data}.zip"
        fail_msg="Unable to upload #{filename}"
        succeeded_msg="https://s3.amazonaws.com/customers.couchbase.com/walmartlabs/#{filename}"
        remote_ssh=RemoteSsh.new(@data.workorder)

        begin
          rs=remote_ssh.execute_ssh_command(node, "sudo /etc/init.d/couchbase-server status | awk '{print $3}'")
          if rs.chomp == 'running'
            auto_failover_enabled(node)

            if @env_profile == 'dev'
              return "\nSTUB: " + succeeded_msg
            end
            remote_ssh.execute_ssh_command(node, "sudo /opt/couchbase/bin/cbcollect_info /tmp/#{filename}")
            remote_ssh.execute_ssh_command(node, "curl  --upload-file /tmp/#{filename} https://s3.amazonaws.com/customers.couchbase.com/walmartlabs/")

            succeeded_msg
          else
            fail_msg
          end
        rescue ClusterException => e
          raise e.message
        rescue Exception => e
          Chef::Log.error e.message
          return fail_msg
        end

      end

      def auto_failover_enabled(node)
        cluster = Couchbase::CouchbaseCluster.new(node, @username, @password)
        if cluster.autofailover_enabled?
          raise ClusterException, "Auto-failover is enabled." +
                                    "Please disable auto failover."
        end
      end

      def cluster_autofailover_enabled

        if !@cluster.autofailover_enabled?
          @errors.push("Auto-failover is not enabled." +
                           " SEE: https://confluence.walmart.com/x/qI6-Bw")
        else
          Chef::Log.info "Auto-failover is enabled."
        end

        return nil
      end

      def cluster_nodes_healthy
        list_nodes=@cluster.list_nodes
        if list_nodes != nil && list_nodes.size > 0
          list_nodes.each { |list_node|
            #puts "node:#{list_node.fetch(:ip)} is #{list_node.fetch(:node_status)}"
            if (list_node.fetch(:node_status).eql?('unhealthy'))
              @errors.push("Node:#{list_node.fetch(:ip)} is #{list_node.fetch(:node_status)}." +
                               " SEE: https://confluence.walmart.com/x/qI6-Bw")
            else
              Chef::Log.info "Node:#{list_node.fetch(:ip)} is #{list_node.fetch(:node_status)}."
            end
          }
        end

      end

      def cluster_data_availability
        @cluster.list_buckets.each { |bucket|
          availability=bucket_data_availability(bucket)
          if !availability.eql?('100.00')
            @errors.push("Bucket:#{bucket} is #{availability}% availability." +
                             " SEE: https://confluence.walmart.com/x/qI6-Bw")
          else
            Chef::Log.info "Bucket:#{bucket} is at #{availability}% availability"
          end
        }

      end

      #Custom formula to compute data availability for a bucket
      def bucket_data_availability(bucket)
        return_value=nil

        healthy_nodes=@cluster.healthy_nodes
        failover_nodes=@cluster.failover_nodes
        bucket_info=@cluster.bucket_info(bucket)
        bucket_nodes_size=bucket_info.nodes_size
        bucket_replica_count=bucket_info.replica

        #puts "data_availability:start: node_size = #{bucket_nodes_size}, replica_count = #{bucket_replica_count}, healthy_nodes = #{healthy_nodes}, failover_nodes = #{failover_nodes}"

        Chef::Log.info "data_availability:start: node_size = #{bucket_nodes_size}, replica_count = #{bucket_replica_count}, healthy_nodes = #{healthy_nodes}, failover_nodes = #{failover_nodes}"

        data_percent_per_node = 1.0 / bucket_nodes_size
        replica_data_percent_per_node = data_percent_per_node * bucket_replica_count
        replica_data_percent_per_node_with_failover = 0

        if (0 < failover_nodes)
          replica_data_percent_per_node_with_failover = replica_data_percent_per_node / (bucket_nodes_size - failover_nodes)
        end

        availability = (data_percent_per_node + replica_data_percent_per_node_with_failover) * healthy_nodes

        if (availability > 1)
          availability = 1
        end
        return_value = "#{'%.2f' % (availability * 100)}"

        Chef::Log.info "data_availability:end: return_value = #{return_value}"

        return return_value

      end

      def cluster_rebalance_needed
        if @cluster.rebalance_needed?
          @errors.push("Rebalance is needed." +
                           " SEE: https://confluence.walmart.com/x/qI6-Bw")
        else
          Chef::Log.info "rebalance is not needed."
        end
      end
      
      def cluster_reset_quota_needed
        if @cluster.need_reset_quota?
          @errors.push("Reset Quota is needed." +
                           " SEE: https://confluence.walmart.com/x/qI6-Bw")
        else
          Chef::Log.info "Reset Quota is not needed."
        end
      end

      def check_for_nodes_mismatch

        # Get list of nodes in OneOps
        workorder_nodes=@nodes.map{ |n| n['ciAttributes']['private_ip'] }.sort
        # Get list of nodes in Couchbase cluster
        list_nodes=@cluster.list_nodes.map{ |n| n.fetch(:ip) }.sort

        Chef::Log.info "check_for_nodes_mismatch: Number of nodes in Couchbase cluster = #{list_nodes.length} " +
                           " and number of nodes in the OneOps workorder = #{workorder_nodes.length}"

        Chef::Log.info "Couchbase node: #{list_nodes.join(', ')}"

        Chef::Log.info "OneOps workorder node: #{workorder_nodes.join(', ')}"

        #Does node count match?
        if workorder_nodes.length != list_nodes.length
          @errors.push("check_for_nodes_mismatch: OneOps ring has #{workorder_nodes.length} nodes whereas the Couchbase cluster shows #{list_nodes.length} nodes")
        end

        diff = workorder_nodes - list_nodes

        if diff != nil && diff.size > 0
          @errors.push("check_for_nodes_mismatch: OneOps ring contains nodes #{diff.join(', ')} not part of Couchbase cluster")
        end

        diff = list_nodes - workorder_nodes

        if diff != nil && diff.size > 0
          @errors.push("check_for_nodes_mismatch: Couchbase cluster has nodes #{diff.join(', ')} not part of the OneOps ring")
        end

      end


      def check_for_buckets_mismatch
        if (!@data.workorder.payLoad.has_key?('cb_buckets'))
          Chef::Log.warn "cb_buckets missing from payLoad"
          return
        end

        oo_bucket = @data.workorder.payLoad.cb_buckets.select { |c| c['ciClassName'].split('.').last == 'Bucket' }.map { |oneops_bucket| oneops_bucket['ciAttributes']['bucketname'] }.sort
        cluster_bucket = @cluster.list_buckets.sort
        Chef::Log.info "check_for_buckets_mismatch: Bucket in Couchbase cluster = #{cluster_bucket.join(', ')}"

        Chef::Log.info "check_for_buckets_mismatch: Bucket in OneOps = #{oo_bucket.join(', ')}"

        if oo_bucket.length != cluster_bucket.length
          @errors.push("check_for_buckets_mismatch: OneOps has #{oo_bucket.length} buckets whereas the Couchbase cluster shows #{cluster_bucket.length} buckets")
        end


        diff = oo_bucket - cluster_bucket
        if diff != nil && diff.size > 0
          @errors.push("check_for_buckets_mismatch: OneOps configuration has buckets #{diff.join(', ')} not configured in Couchbase")
        end

        diff = cluster_bucket - oo_bucket
        if diff != nil && diff.size > 0
          @errors.push("check_for_buckets_mismatch: Couchbase has buckets #{diff.join(', ')} not configured in OneOps")
        end

      end


      def check_multiple_nodes_on_same_hv

        # create a hash with the node_ip and hypervisor attributes
        computes = Hash.new

        @nodes.each do |compute_node|
          computes[compute_node['ciAttributes']['private_ip']] = compute_node['ciAttributes']['hypervisor']
        end

        duplicates = computes.group_by { |compute| compute[1] }.values.select { |compute| compute.size > 1 }.flatten

        if (duplicates.length > 0)
          @errors.push("check_multiple_nodes_on_same_hv : Detected multiple nodes on the same hypervisor. #{duplicates.join(', ' )}")
        else
          Chef::Log.info 'check_multiple_nodes_on_same_hv: No duplicate hypervisors found. All nodes on unique hypervisors'
        end

      end


      def cluster_health_check
        @errors = []

        cluster_autofailover_enabled
        cluster_nodes_healthy
        cluster_data_availability
        cluster_rebalance_needed
        check_for_nodes_mismatch
        check_for_buckets_mismatch
        cluster_reset_quota_needed
        check_multiple_nodes_on_same_hv

        log_errors("cluster health check failed")
      end

      def log_errors(msg_raise)
        if @errors.length > 0
          @errors.each { |msg|
            Chef::Log.error "#{msg}"
          }
          raise msg_raise
        end
      end

      def autofailover_enable
        @cluster.autofailover(true, @cluster.autofailover_timeout)

        Chef::Log.info("COUCHBASE AUTO-FAILOVER STATUS: #{@cluster.autofailover_enabled? ? 'ENABLED' : 'DISABLED'}")
      end

      def autofailover_disable
        @cluster.autofailover(false, @cluster.autofailover_timeout)

        Chef::Log.info("COUCHBASE AUTO-FAILOVER STATUS: #{@cluster.autofailover_enabled? ? 'ENABLED' : 'DISABLED'}")
      end

    end
  end
end
