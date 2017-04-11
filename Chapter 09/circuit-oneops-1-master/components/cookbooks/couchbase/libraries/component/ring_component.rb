module Couchbase
    module Component
        class RingComponent

            @data
            @cluster

            def initialize(data)

                @data = data

                attributes = find_attributes
                ip = attributes["ip"]
		username = attributes["adminuser"]
                password = attributes["adminpassword"]

                @cluster = Couchbase::CouchbaseCluster.new(ip, username, password)

            end

            def find_attributes

                compute_nodes = @data["workorder"]["payLoad"]["ManagedVia"]
                first_couchbase_node = @data["workorder"]["payLoad"]["DependsOn"][0]

                compute_nodes.each do |node|
                  if node["rfcAction"] != "add"
                    if node['ciAttributes'].has_key?("public_ip") && !node['ciAttributes']['public_ip'].empty?
	              ip_address=node['ciAttributes']["public_ip"]
		    else
		      ip_address=node['ciAttributes']["private_ip"]
		    end

                    return {
                            "ip" => ip_address,
                            "adminuser" => first_couchbase_node["ciAttributes"]["adminuser"],
                            "adminpassword" => first_couchbase_node["ciAttributes"]["adminpassword"]
                        }
                  end

                end
                # must be creating cluster or updating it
                return {
                    "ip" => "localhost",
                    "adminuser" => first_couchbase_node["ciAttributes"]["adminuser"],
                    "adminpassword" => first_couchbase_node["ciAttributes"]["adminpassword"]
                }

            end

            def adding?

                # loop over nodes looking for rfcAction
                couchbase_nodes = @data["workorder"]["payLoad"]["DependsOn"]

                nodes_to_add = []
                existing_nodes = []

                couchbase_nodes.each do |node|

                    if node["rfcAction"] == "add"
                        nodes_to_add.push(node)
                    else
                        existing_nodes.push(node)
                    end

                end

                # A node is being added if there are existing nodes in the cluster
                return nodes_to_add.length > 0 && existing_nodes.length > 0

            end

            def validate

                if adding?

                    if !@cluster.all_active?
                        raise "One or more nodes in the cluster are not active members." +
                                  " SEE: https://confluence.walmart.com/x/qI6-Bw"
                    end

                    if !@cluster.all_healthy?
                        raise "One or more nodes in the cluster are not healthy." +
                                  " SEE: https://confluence.walmart.com/x/qI6-Bw"
                    end

                    if @cluster.rebalance?
                        raise "Rebalance in progress." +
                                  " SEE: https://confluence.walmart.com/x/qI6-Bw"
                    end

                end

            end

        end
    end
end
