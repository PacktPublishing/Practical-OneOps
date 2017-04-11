# module that contains helper methods
# this helps remove duplication and isolate the methods for unit testing
module PanosUtils

  def get_service_info(node)
    service_hash = {}

    cloud_name = node[:workorder][:cloud][:ciName]
    Chef::Log.info("Cloud Name: #{cloud_name}")

    # get the service information
    if node[:workorder][:services].has_key?(:firewall)
      Chef::Log.info("FW SERVICE IS: #{node[:workorder][:services][:firewall]}")
      fw_attributes = node[:workorder][:services][:firewall][cloud_name][:ciAttributes]
      service_hash[:url_endpoint] = fw_attributes[:endpoint]
      service_hash[:username] = fw_attributes[:username]
      service_hash[:password] = fw_attributes[:password]
    end

    service_hash
  end

  def get_computes(node)
    addresses = Hash.new { |h,k| h[k] = Array.new }

    # get all the computes we are dealing with
    if !node[:workorder][:payLoad].has_key?(:RequiresComputes)
      msg = 'RequiresComputes does not exist for compute and firewall'
      puts "***FAULT:FATAL=#{msg}"
      e = Exception.new(msg)
      raise e
    else
      nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
      org_name = nsPathParts[1]
      assembly_name = nsPathParts[2]
      environment_name = nsPathParts[3]
      platform_name = nsPathParts[5]
      # for the Computes, need to add to an array and submit those to be created/updated/deleted in the firewall
      computes = node[:workorder][:payLoad][:RequiresComputes].select { |d| d[:ciClassName] =~ /Compute/ }
      computes.each do |compute|
        instance_name = 'oa-' + platform_name[0..15] + '-' + environment_name[0..10] + '-' + assembly_name[0..10] + '-' + org_name[0..10] + '-' + compute[:ciId].to_s
        if instance_name.length > 63
          instance_name = 'oa-' + platform_name[0..10] + '-' + environment_name[0..10] + '-' + assembly_name[0..10] + '-' + org_name[0..10] + '-' + compute[:ciId].to_s
        end
        ip_address = compute[:ciAttributes][:private_ip]
        addresses['entries'] << {'name' => instance_name, 'ip_address' => ip_address}
      end
    end

    addresses
  end

  def get_address_group_name(node)
    # get the tag name and address group name
    nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
    org_name = nsPathParts[1]
    assembly_name = nsPathParts[2]
    environment_name = nsPathParts[3]
    platform_ciid = node.workorder.box.ciId.to_s

    address_group_name = 'og-' + org_name[0..15] + '-' + assembly_name[0..15] + '-' + platform_ciid + '-' + environment_name[0..15]
    address_group_name
  end

  def get_tag_name(node)
    # get the tag name
    nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
    org_name = nsPathParts[1]
    assembly_name = nsPathParts[2]
    environment_name = nsPathParts[3]
    platform_ciid = node.workorder.box.ciId.to_s

    tag = org_name[0..15] + '-' + assembly_name[0..15] + '-' + platform_ciid + '-' + environment_name[0..15]
    tag
  end

  def get_device_groups(node)
    devicegroups = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:devicegroups])
    devicegroups
  end

  module_function :get_service_info, :get_computes, :get_address_group_name, :get_tag_name, :get_device_groups

end
