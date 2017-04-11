require 'azure_mgmt_compute'
require File.expand_path('../../libraries/resource_group_manager.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Compute)
::Chef::Recipe.send(:include, Azure::ARM::Compute::Models)

module AzureBase
  class AvailabilitySetManager < AzureBase::ResourceGroupManager

    attr_accessor :as_name

    def initialize(node)
      super(node)
      # set availability set name same as resource group name
      @as_name = @rg_name
      @client = Azure::ARM::Compute::ComputeManagementClient.new(@creds)
      @client.subscription_id = @subscription
    end

    # method will get the availability set using the resource group and
    # availability set name
    # will return whether or not the availability set exists.
    def get
      begin
        promise = @client.availability_sets.get(@rg_name,@as_name).value!
        return promise
      rescue MsRestAzure::AzureOperationError => e
        # if the error is that the availability set doesn't exist,
        # just return a nil
        if e.response.status == 404
          puts 'Availability Set Not Found!  Create It!'
          return nil
        end
        OOLog.fatal("Error getting availability set: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting availability set: #{ex.message}")
      end
    end

    # this method will add the availability set if needed.
    # it first checks to make sure the availability set exists,
    # if not, it will create it.
    def add
      # check if it exists
      as = get
      if !as.nil?
        OOLog.info("Availability Set #{as.name} exists in the #{as.location} region.")
      else
        # need to create the availability set
        OOLog.info("Creating Availability Set
                      '#{@as_name}' in #{@location} region")
        avail_set = get_avail_set_props
        begin
          response =
            @client.availability_sets.create_or_update(@rg_name,
                                                       @as_name,
                                                       avail_set).value!
          return response
        rescue MsRestAzure::AzureOperationError => e
          OOLog.fatal("Error adding an availability set: #{e.body}")
        rescue => ex
          OOLog.fatal("Error adding an availability set: #{ex.message}")
        end
      end
    end

    private

    # create the properties object for creating availability sets
    def get_avail_set_props
      avail_set_props =
        Azure::ARM::Compute::Models::AvailabilitySetProperties.new
      # At least two domain faults
      avail_set_props.platform_fault_domain_count = 2
      avail_set_props.platform_update_domain_count = 2
      # At this point we do not have virtual machines to include
      avail_set_props.virtual_machines = []
      avail_set_props.statuses = []
      avail_set = Azure::ARM::Compute::Models::AvailabilitySet.new
      avail_set.location = @location
      avail_set.properties = avail_set_props
      return avail_set
    end

  end
end
