require File.expand_path('../dataaccess/tag_request.rb', __FILE__)
require File.expand_path('../dataaccess/address_group_request.rb', __FILE__)
require File.expand_path('../models/address_group.rb', __FILE__)
require File.expand_path('../dataaccess/key_request.rb', __FILE__)
require File.expand_path('../models/key.rb', __FILE__)
require File.expand_path('../dataaccess/address_request.rb', __FILE__)
require File.expand_path('../models/address.rb', __FILE__)
require File.expand_path('../dataaccess/commit_request.rb', __FILE__)
require File.expand_path('../models/panos_job.rb', __FILE__)
require File.expand_path('../dataaccess/status_request.rb', __FILE__)
require File.expand_path('../models/status.rb', __FILE__)

# this class handles coordinating with the request classes to perform operations on
# the PANOS firewall device
class AddressManager

  # initialize the manager class with a URL, username, and password
  def initialize(url, username, password)
    # get the key
    keyrequest = KeyRequest.new(url, username, password)
    @key = keyrequest.getkey
    @url = url
  end

  # This function handles updating the firewall device
  def update(addresses, tag_name, device_groups)
    device_groups.each do |device_group|
      #  convert address hash to an array of Address objects.
      # do this for easier comparison of the existing addresses in the firewall
      deploy_addresses = []
      addresses['entries'].each do |deploy_addr|
        deploy_addresses.push(Address.new(deploy_addr['name'], 'IP_NETMASK', deploy_addr['ip_address'], device_group, tag_name))
      end

      address = AddressRequest.new(@url, @key)

      # get the existing addresses from the firewall
      # this is an array of Address objects
      existing_addresses = address.get_all_for_tag(tag_name, device_group)

      # array holders for actions to be taken later
      delete_address = []
      create_address = []
      update_address = []

      Chef::Log.info("Existing addresses: #{existing_addresses}")
      Chef::Log.info("Deployment addresses: #{deploy_addresses}")

      # compare with my hash of addresses from the deployment
      existing_addresses.each do |addr|
        if !deploy_addresses.include?(addr)
          # address from firewall is not in deployment, delete it
          delete_address.push(addr)
        end
      end

      # these are the addresses passed into the method, the new or updated addresses.
      deploy_addresses.each do |dep_addr|
        if existing_addresses.include?(dep_addr)
          # both arrays have the address, add it to the update array
          update_address.push(dep_addr)
        else
          # if the deployment address is not found on the firewall
          # we need to create it
          create_address.push(dep_addr)
        end
      end

      # delete the addresses the firewall has that the deployment doesn't
      Chef::Log.info("Delete address are: #{delete_address}")
      if delete_address.size > 0
        delete_address.each do |del_addr|
          address.delete(del_addr.name, device_group)
        end
      end

      # add the addresses the deployment has the firewall doesn't
      Chef::Log.info("Create address are: #{create_address}")
      if create_address.size > 0
        create_address.each do |create_addr|
          address.create(create_addr)
        end
      end

      # update the addresses that both have
      Chef::Log.info("Update address are: #{update_address}")
      if update_address.size > 0
        update_address.each do |update_addr|
          address.update(update_addr)
        end
      end
    end

    commit_and_check_status(device_groups)
  end

  # this function creates the tag, addresses and dynamic address group
  def create_dag_with_addresses(address_group_name, addresses, tag, device_groups)
    device_groups.each do |device_group|
      # create the tag that will be used
      tag_request = TagRequest.new(@url, @key)
      tag_request.create(tag, device_group)

      # create a DAG
      addr_group = AddressGroup.new(address_group_name, 'Dynamic', tag, device_group)
      dag_request = AddressGroupRequest.new(@url, @key)
      dag_request.create(addr_group)

      # create the address
      address_request = AddressRequest.new(@url, @key)
      addresses['entries'].each do |address|
        Chef::Log.info("Address is: #{address}")
        Chef::Log.info("NAME is: #{address['name']}")
        Chef::Log.info("IP Address is: #{address['ip_address']}")
        address_request.create(Address.new(address['name'], 'IP_NETMASK', address['ip_address'], device_group, tag))
      end
    end

    commit_and_check_status(device_groups)
  end

  # this function deletes the addresses and address group from the firewall
  def delete_addresses_and_dag(address_group_name, addresses, device_groups)
    device_groups.each do |device_group|
      # delete the addresses
      address_request = AddressRequest.new(@url, @key)
      addresses['entries'].each do |address|
        Chef::Log.info("Address is: #{address}")
        Chef::Log.info("NAME is: #{address['name']}")
        address_request.delete(address['name'], device_group)
      end

      # delete the dag
      dag_request = AddressGroupRequest.new(@url, @key)
      dag_request.delete(address_group_name, device_group)
    end

    commit_and_check_status(device_groups)
  end

  private

  # reusable function to commit the changes to the firewall and check the status
  # of the async job that is queued.
  def commit_and_check_status(device_groups)
    device_groups.each do |device_group|
      # commit the changes on the firewall device
      commit = CommitRequest.new(@url, @key)
      job = commit.commit_configs(device_group)

      if !job.nil?
        # check status until complete
        # won't continue until the update is complete.
        status = StatusRequest.new(@url, @key)
        until status.job_complete?(job) do
          Chef::Log.info("job, #{job.id} still in progress")
          sleep(5)
        end

        Chef::Log.info("Job, #{job.id} complete!")
      end
    end
  end

end
