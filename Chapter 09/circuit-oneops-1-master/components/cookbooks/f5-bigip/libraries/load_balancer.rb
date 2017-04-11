#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer
#
# add currrent dir to load path
$LOAD_PATH << File.dirname(__FILE__)

require 'load_balancer_ltm'

module F5
  # The F5 device
  include Chef::Mixin::ShellOut
  class LoadBalancer
    attr_accessor :name, :client

    def initialize(name, client)
      @name = name
      @client = client
    end

    #
    # LTM resources for load balancer
    #
    def ltm
      @ltm ||= F5::LoadBalancer::Ltm.new(client)
    end

    #
    # List of device groups the load balancer is a part of
    #
    def device_groups
      @device_groups ||= client['Management.DeviceGroup']
                           .get_list
                           .delete_if { |g| g =~ /device_trust_group/ || g == '/Common/gtm' }
    end

    #
    # Hostname as configured on the F5
    #
    def system_hostname
      @system_hostname ||= client['System.Inet'].get_hostname
    end

    #
    # Return whether the f5 device is active
    #
    def active?
      state == 'FAILOVER_STATE_ACTIVE'
    end

    private

    #
    # Get the failover state of the f5
    #
    def state
      @state ||= client['System.Failover'].get_failover_state
    end
  end
end
