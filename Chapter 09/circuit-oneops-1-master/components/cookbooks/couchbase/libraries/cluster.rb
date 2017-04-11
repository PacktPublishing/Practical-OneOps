class Chef::Recipe::Cluster
  attr_accessor :ips, :this_node, :ip

  def initialize(node)
    @this_node = node
    @ips = Array.new
  end

  def getAction
    Chef::Log.info "Getting Action"

    if !@this_node.workorder.payLoad.has_key?("cb_cmp")
      Chef::Log.info("cb_cmp not found in payLoad, assume remove_cluster")
      return "remove_cluster"
    end
    
    @this_node.workorder.payLoad.cb_cmp.each do |n|
      if node['ciAttributes'].has_key?("public_ip") && !node['ciAttributes']['public_ip'].empty?
	ip_address=node['ciAttributes']["public_ip"]
      else
        ip_address=node['ciAttributes']["private_ip"]
      end
      action = n[:rfcAction] == 'delete' ? 'delete' : 'nothing'
      @ips.push(Chef::Recipe::Node.new(ip_address, action))
    end

    removing = @ips.select  { |n| n.action == 'delete' }

    if removing.size == 0
      Chef::Log.error("No nodes to remove.")
      return "remove_nothing"
    elsif removing.size == 1
      @ip = removing[0].ip_address
      return "remove_single_node"
    elsif removing.size > 1
      Chef::Log.error("Removing more than 1 node. count=#{removing.size}")
      return "remove_nothing"
    end

  end

end
