#
# Cookbook Name:: f5-bigip
# Resource:: ltm_pool
#

class Chef
  class Resource
    #
    # Chef Resource for F5 LTM Pool
    #
    class  F5LtmPool < Chef::Resource
    require_relative "./provider_ltm_pool"
      PORTS_REGEX ||= /^(6553[0-5]|655[0-2]\d|65[0-4]\d\d|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}|0)$/
      LB_METHODS ||= %w(
        LB_METHOD_ROUND_ROBIN
        LB_METHOD_RATIO_MEMBER
        LB_METHOD_LEAST_CONNECTION_MEMBER
        LB_METHOD_OBSERVED_MEMBER
        LB_METHOD_PREDICTIVE_MEMBER
        LB_METHOD_RATIO_NODE_ADDRESS
        LB_METHOD_LEAST_CONNECTION_NODE_ADDRESS
        LB_METHOD_FASTEST_NODE_ADDRESS
        LB_METHOD_OBSERVED_NODE_ADDRESS
        LB_METHOD_PREDICTIVE_NODE_ADDRESS
        LB_METHOD_DYNAMIC_RATIO
        LB_METHOD_FASTEST_APP_RESPONSE
        LB_METHOD_LEAST_SESSIONS
        LB_METHOD_DYNAMIC_RATIO_MEMBER
        LB_METHOD_L3_ADDR
        LB_METHOD_UNKNOWN
        LB_METHOD_WEIGHTED_LEAST_CONNECTION_MEMBER
        LB_METHOD_WEIGHTED_LEAST_CONNECTION_NODE_ADDRESS
        LB_METHOD_RATIO_SESSION
        LB_METHOD_RATIO_LEAST_CONNECTION_MEMBER
        LB_METHOD_RATIO_LEAST_CONNECTION_NODE_ADDRESS
      )

      attr_accessor :exists, :monitor_type

      def initialize(name, run_context = nil)
        super
        @resource_name = :f5_ltm_pool
        @provider = Chef::Provider::F5LtmPool
        @action = :create
        @allowed_actions = [:create, :delete]

        # This is equivalent to setting :name_attribute => true
        @pool_name = name

        # Now we need to set up any resource defaults
        @lb_method = 'LB_METHOD_ROUND_ROBIN'
        @monitors = []
        @members = []
      end

      def pool_name(arg = nil)
        set_or_return(:pool_name, arg, :kind_of => String, :required => true)
      end

      def f5(arg = nil)
        set_or_return(:f5, arg, :kind_of => String, :required => true)
      end

      def lb_method(arg = nil)
        set_or_return(:lb_method, arg, :kind_of => String, :equal_to => LB_METHODS)
      end

      def monitors(arg = nil)
        set_or_return(:monitors, arg, :kind_of => Array)
      end

      def members(arg = nil)
        set_or_return(:members, arg, :kind_of => Array)
      end
    end
  end
end
