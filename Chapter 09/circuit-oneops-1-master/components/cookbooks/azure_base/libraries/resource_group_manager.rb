require 'azure_mgmt_resources'
require File.expand_path('../../libraries/azure_base_manager.rb', __FILE__)

::Chef::Recipe.send(:include, Azure::ARM::Resources)
::Chef::Recipe.send(:include, Azure::ARM::Resources::Models)

module AzureBase
  # class to handle operations on the Azure Resource Group
  # this is the base class, other classes will extend
  class ResourceGroupManager < AzureBase::AzureBaseManager

    attr_accessor :rg_name,
                  :org,
                  :assembly,
                  :environment,
                  :platform_ci_id,
                  :location,
                  :subscription

    def initialize(node)
      super(node)

      # get the info needed to get the resource group name
      nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
      @org = nsPathParts[1]
      @assembly = nsPathParts[2]
      @environment = nsPathParts[3]
      @platform_ci_id = node[:workorder][:box][:ciId]
      if @service[:location] != nil
       @location = @service[:location]
      elsif @service[:region] != nil
       @location = @service[:region]
      end
      @subscription = @service[:subscription]

      @rg_name = get_name
      @client = Azure::ARM::Resources::ResourceManagementClient.new(@creds)
      @client.subscription_id = @subscription
    end

    # this method will create/update the resource group with the info passed in
    def add
      begin
        # get the name
        @rg_name = get_name if @rg_name.nil?
        OOLog.info("RG Name is: #{@rg_name}")
        # check if the rg is there
        if !exists?
          OOLog.info("RG does NOT exists.  Creating...")
          # create it if it isn't.
          resource_group = Azure::ARM::Resources::Models::ResourceGroup.new
          resource_group.location = @location
          response =
            @client.resource_groups.create_or_update(@rg_name,
                                                     resource_group).value!
          return response
        else
          OOLog.info("Resource Group, #{@rg_name} already exists.  Moving on...")
        end
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error creating resource group: #{e.body}")
      rescue => ex
        OOLog.fatal("Error creating resource group: #{ex.message}")
      end
    end

    # This method will retrieve the resource group from azure.
    # if the resource group is not found it will return a nil.
    def exists?
      begin
        response = @client.resource_groups.check_existence(@rg_name).value!
        return response.body
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error checking resource group: #{@rg_name}. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error checking resource group: #{ex.message}")
      end
    end

    # This method will delete the resource group
    def delete
      begin
        response = @client.resource_groups.delete(@rg_name).value!
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error deleting resource group: #{e.body}")
      rescue => ex
        OOLog.fatal("Error deleting resource group: #{ex.message}")
      end
    end

    # this method will return the resource group and availability set names
    # in the correct format
    # There is a hard limit of 64 for the name in azure, so we are taking
    # 15 chars from org, assembly, env, and abbreviating the location
    # The reason we include org/assembly/env/platform/location in the name of
    # the resource group is; we needed something that would be unique for an org
    # accross the whole subscription, we want to be able to provision and
    # de-provision platforms in the same assembly / env / location without
    # destroying all of them together.
    def get_name
      resource_group_name = @org[0..15] + '-' +
        @assembly[0..15] + '-' +
        @platform_ci_id.to_s + '-' +
        @environment[0..15] + '-' +
        Utils.abbreviate_location(@location)
      return resource_group_name
    end
  end
end
