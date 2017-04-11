
def whyrun_supported?
  true
end

action :update do
  begin
    converge_by("Update Addresses") do
      address_manager = AddressManager.new(@new_resource.url_endpoint, @new_resource.username, @new_resource.password)
      raise Exception.new("Tag is required") if @new_resource.tag.nil?
      raise Exception.new("Address hash is required") if @new_resource.addresses.nil?

      address_manager.update(@new_resource.addresses, @new_resource.tag, @new_resource.devicegroups)
    end

    @new_resource.updated_by_last_action(true)
  rescue => e
    msg = "Exception updating the firewall: #{e}"
    puts "***FAULT:FATAL=#{msg}"
    e = Exception.new(msg)
    raise e
  end
end

action :add do
  begin
    converge_by("Add computes to FW and create Dynamic Address Group") do
      address_manager = AddressManager.new(@new_resource.url_endpoint, @new_resource.username, @new_resource.password)
      raise Exception.new("AddressGroupName is required") if @new_resource.address_group_name.nil?
      raise Exception.new("Tag is required") if @new_resource.tag.nil?
      raise Exception.new("Address hash is required") if @new_resource.addresses.nil?

      address_manager.create_dag_with_addresses(@new_resource.address_group_name, @new_resource.addresses, @new_resource.tag, @new_resource.devicegroups)
    end

    @new_resource.updated_by_last_action(true)
  rescue => e
    msg = "Exception creating new DAG with addresses in the firewall: #{e}"
    puts "***FAULT:FATAL=#{msg}"
    e = Exception.new(msg)
    raise e
  end
end

action :delete do
  begin
    converge_by("Add computes to FW and create Dynamic Address Group") do
      address_manager = AddressManager.new(@new_resource.url_endpoint, @new_resource.username, @new_resource.password)
      raise Exception.new("AddressGroupName is required") if @new_resource.address_group_name.nil?
      raise Exception.new("Address hash is required") if @new_resource.addresses.nil?

      address_manager.delete_addresses_and_dag(@new_resource.address_group_name, @new_resource.addresses, @new_resource.devicegroups)
    end

    @new_resource.updated_by_last_action(true)
  rescue => e
    msg = "Exception deleting DAG with addresses from the firewall: #{e}"
    puts "***FAULT:FATAL=#{msg}"
    e = Exception.new(msg)
    raise e
  end
end
