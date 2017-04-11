#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer::Ltm
#
require 'load_balancer_ltm_monitors'
require 'load_balancer_ltm_pools'
require 'load_balancer_ltm_virtual_servers'

module F5
  include Chef::Mixin::ShellOut
  class LoadBalancer
    # Class representing resources in a Local Traffic Manager
    class Ltm
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def nodes # rubocop:disable MethodLength
        @nodes ||= begin
          node_list = client['LocalLB.NodeAddressV2'].get_list

          # Check if empty
          return [] if node_list.empty?

          addresses = client['LocalLB.NodeAddressV2'].get_address(node_list)
          statuses = client['LocalLB.NodeAddressV2'].get_object_status(node_list)

          states = statuses.map { |status| status['enabled_status'] != 'ENABLED_STATUS_DISABLED' }

          node_list.each_with_index.map do |node, index|
            { 'name' => node, 'address' => addresses[index], 'enabled' => states[index] }
          end
        end
      end

      def pools
        @pools ||= F5::LoadBalancer::Ltm::Pools.new(client)
      end

      def virtual_servers
        @virtual_servers ||= F5::LoadBalancer::Ltm::VirtualServers.new(client)
      end

      def monitors
        @monitors ||= F5::LoadBalancer::Ltm::Monitors.new(client)
      end

      def sslprofiles
	      @sslprofiles ||= begin
          sslprofiles_list = client['LocalLB.ProfileClientSSL'].get_list
          return [] if sslprofiles_list.empty?

          sslprofiles_list
        end
      end

      def ssls(mode)
        @ssls ||= begin
          ssl_ids = client['Management.KeyCertificate'].get_key_list("#{mode}").map {|p| p['key_info']['id']}
		    return [] if ssl_ids.empty?

		    ssl_ids
        end
      end
    end
  end
end
