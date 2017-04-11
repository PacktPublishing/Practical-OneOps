#
# Cookbook Name:: f5-bigip
# Resource:: config_sync
#
require_relative "./provider_config_sync"
class Chef
  class Resource
    #
    # Chef Resource for F5 Config Sync
    #
    class  F5ConfigSync < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :f5_config_sync
        @provider = Chef::Provider::F5ConfigSync
        @action = :nothing
        @allowed_actions = [:nothing, :run]

        @f5 = name
      end

      def f5(arg = nil)
        set_or_return(:f5, arg, :kind_of => String, :required => true)
      end
    end
  end
end
