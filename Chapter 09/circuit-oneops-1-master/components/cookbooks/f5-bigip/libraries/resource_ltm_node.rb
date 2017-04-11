#
# Cookbook Name:: f5-bigip
# Resource:: ltm_node
#

class Chef
  class Resource
    #
    # Chef Resource for F5 LTM Node
    #
    class  F5LtmNode < Chef::Resource
      require_relative "./provider_ltm_node"
      def initialize(name, run_context = nil)
        super
        @resource_name = :f5_ltm_node
        @provider = Chef::Provider::F5LtmNode
        @action = :create
        @allowed_actions = [:create, :delete]

        # This is equivalent to setting :name_attribute => true
        @node_name = name

        # Now we need to set up any resource defaults
        @enabled = true
      end

      def node_name(arg = nil)
        set_or_return(:node_name, arg, :kind_of => String, :required => true)
      end

      def address(arg = nil)
        # Set to @node_name if not set as a 'default' for backward compatibility
        set_or_return(:address, @node_name, :kind_of => String, :required => true) if @address.nil?

        set_or_return(:address, arg, :kind_of => String, :required => true)
      end

      def f5(arg = nil)
        set_or_return(:f5, arg, :kind_of => String, :required => true)
      end

      def enabled(arg = nil)
        set_or_return(:enabled, arg, :kind_of => [TrueClass, FalseClass])
      end

      attr_accessor :exists
    end
  end
end
