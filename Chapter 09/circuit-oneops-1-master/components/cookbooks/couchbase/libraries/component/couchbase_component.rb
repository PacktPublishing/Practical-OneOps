module Couchbase
    module Component
        class CouchbaseComponent

            @data
            @cluster
            @ip
            @port
            @username
            @password

            def initialize(data)

                @data = data

                attributes = data["couchbase"]
                @ip = "localhost"
                @port = attributes["port"]
                @username = attributes["adminuser"]
                @password = attributes["adminpassword"]
            end

            def execute
      
                @data.run_list.each { |action|
                  if action.name == "couchbase::remove-from-cluster"
                    remove_from_cluster
                  elsif action.name == "couchbase::add-to-cluster"
                    add_to_cluster
                  elsif action.name == "couchbase::update"
                    update
                  else
                    Chef::Log.warn "unknown action #{action}"
                  end
                }
      
            end
          
            def validate

                @cluster = Couchbase::CouchbaseCluster.new(@ip, @username, @password)
              
                if !@cluster.all_active?
                    raise "One or more nodes in the cluster are not active members." +
                              " SEE: https://confluence.walmart.com/x/qI6-Bw"
                end

                if !@cluster.all_healthy?
                    raise "One or more nodes in the cluster are not healthy." +
                              " SEE: https://confluence.walmart.com/x/qI6-Bw"
                end
                
                validate_rebalance
            end
            
            def validate_rebalance

                if @cluster.rebalance?
                    raise "Rebalance in progress." +
                              " SEE: https://confluence.walmart.com/x/qI6-Bw"
                end

            end

            def remove_from_cluster

                @cluster = Couchbase::CouchbaseCluster.new(@ip, @username, @password)
                outgoing_node_ip = @data.workorder.payLoad.ManagedVia.first.ciAttributes.private_ip
                servers = []
                begin
                  servers = @cluster.list_servers
                rescue Exception => e
                  raise "server #{outgoing_node_ip} is already not part of the cluster. #{e}"
                end

                if !servers.include?("#{outgoing_node_ip}:#{@port}")
                  raise "server #{outgoing_node_ip} is already not part of the cluster." 
                end
                
                if servers.length <= 1
                  raise "single node cluster detected, cannot remove from cluster"
                end
                
                # use Ip of different server in cluster
                ip = servers.select{ |n| n != "#{outgoing_node_ip}:#{@port}" }.first
  
                @cluster=Couchbase::CouchbaseCluster.new(ip.split(':')[0], @username, @password)
  
                validate_rebalance   
                
                Chef::Log.info "removing #{outgoing_node_ip} from cluster and rebalancing"           
                
                @cluster.remove_node_with_rebalance(outgoing_node_ip, @port)
                
                validate_rebalance
                
                if @cluster.list_servers.include?("#{outgoing_node_ip}:#{@port}")
                  raise "server #{outgoing_node_ip} is still part of the cluster." 
                end

                Chef::Log.info "completed removing #{outgoing_node_ip} from cluster"
            end

            def add_to_cluster
                if !@data.workorder.payLoad.has_key?('cb_cmp')
                  Chef::Log.warn "Missing cb_cmp array from payLoad"
                  return
                end
                                  
                incoming_node_ip = @data.workorder.payLoad.ManagedVia.first.ciAttributes.private_ip

                # use Ip of different server in cluster
                @data.workorder.payLoad.cb_cmp.each do |n|
                  ip=n['ciAttributes']['private_ip']
                  if (ip != incoming_node_ip)
                    begin
                      @cluster = Couchbase::CouchbaseCluster.new(ip, @username, @password)
                      if (@cluster.list_servers.size > 0)
                        break
                      end
                    rescue Exception => e
                      Chef::Log.warn "NODE:#{ip} #{e.message}"
                    end
                  end
                end

                if @cluster.list_servers.include?("#{incoming_node_ip}:#{@port}")
                  Chef::Log.info "server #{incoming_node_ip} is already part of the cluster."
                  return 
                end
                
                validate_rebalance   
                
                Chef::Log.info "adding #{incoming_node_ip} to cluster and rebalancing"           
                
                @cluster.add_node(incoming_node_ip, @port)
                
                validate_rebalance
                
                if !@cluster.list_servers.include?("#{incoming_node_ip}:#{@port}")
                  raise "server #{incoming_node_ip} is still not part of the cluster." 
                end

                Chef::Log.info "completed adding #{incoming_node_ip} to cluster"
                
            end
            
            def update
                
                if !@data.workorder.has_key?('rfcCi')
                  Chef::Log.warn 'Missing rfcCi object from workorder'
                  return
                end
                
                ci = @data.workorder.rfcCi
                
                if !ci.has_key?('ciBaseAttributes')
                  Chef::Log.info 'Missing ciBaseAttributes object'
                  return
                end

                begin
                  Couchbase::CouchbaseCluster.new(@ip, @username, @password)
                rescue InvalidCredentialsError => e

                  verify_credentials_change = false                    
                  if ci.ciBaseAttributes.has_key?('adminpassword')
                    # Update password if user changed password
                    Chef::Log.info "Changing password"
                    Couchbase::CouchbaseResetPassword.new().reset_password(@password)
                    verify_credentials_change = true
                  end
  
                  if ci.ciBaseAttributes.has_key?('adminuser')
                    # Update admin user using cluster-edit command
                    Chef::Log.info "Changing user #{ci.ciBaseAttributes.adminuser} to #{@username}"
                    Couchbase::CouchbaseCLI.new(@ip, ci.ciBaseAttributes.adminuser, @password).edit_cluster(@username)
                    verify_credentials_change = true
                  end
                  
                  if verify_credentials_change
                    # Validate connection
                    begin
                      Couchbase::CouchbaseCluster.new(@ip, @username, @password)
                    rescue InvalidCredentialsError => e
                      raise "could not update username/password #{e}"
                    end
                  end
                end
                
            end

        end
    end
end
