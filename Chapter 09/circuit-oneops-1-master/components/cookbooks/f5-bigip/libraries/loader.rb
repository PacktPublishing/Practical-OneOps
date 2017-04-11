#
# Cookbook Name:: f5-bigip
# Library:: loader
#
#require 'load_balancer.rb'
module F5
  # rubocop:disable ClassVars, MethodLength
  # Loader function to load data from f5 to compare resources to
  module Loader
    #require File.expand_path('../helpers.rb', __FILE__)
    #require File.expand_path('../load_balancer.rb', __FILE__)
    require_relative "./helpers"
    require_relative "./load_balancer"
    include F5::Helpers

    #
    # Convert to Array
    #
    # @param [Object] item to make sure is an Array
    #
    # @return [Array] if obj was already an Array it returns the obj.  Otherwise
    #   returns a single element Array of the obj
    #
    def convert_to_array(obj)
      obj = [obj] unless obj.is_a? Array
      obj
    end

    # Method call to require f5-icontrol
    # after chef_gem has had a chance to run
    def load_dependencies
      require 'f5-icontrol'
    end

    #
    # Interfaces to load from F5 icontrol
    #
    # @return [Array<String>] list of interfaces to load from F5 icontrol
    #
    def interfaces
      [
        'LocalLB.Monitor',
        'LocalLB.NodeAddressV2',
        'LocalLB.Pool',
        'LocalLB.VirtualServer',
        'Management.DeviceGroup',
        'System.ConfigSync',
        'System.Failover',
        'System.Inet',
        'Management.KeyCertificate',
        'LocalLB.ProfileClientSSL'
      ]
    end

    #
    # Retrieve/Create load balancer from list of load balancers for a resource
    #
    # @return [F5::LoadBalancer] instance of F5::LoadBalancer matching the resource
    #
    def load_balancer
      fail 'Can not determine hostname to load client for' if @new_resource.f5.nil?
      @@load_balancers ||= []
      add_lb(@new_resource.f5) if @@load_balancers.empty?
      add_lb(@new_resource.f5) if @@load_balancers.find { |lb| lb.name == @new_resource.f5 }.nil?
      @@load_balancers.find { |lb| lb.name == @new_resource.f5 }
    end

    def search_virtual_server(f5_hostname)
      @@load_balancers ||= []
      add_lb(f5_hostname) if @@load_balancers.empty?
      add_lb(f5_hostname) if @@load_balancers.find { |lb| lb.name == f5_hostname }.nil?
      @@load_balancers.find { |lb| lb.name == f5_hostname }
    end

    #
    # Add new load balancer to list of load balancers
    #
    # @param hostname [String] hostname of load balancer to add
    #
    def add_lb(hostname)
      @@load_balancers << LoadBalancer.new(hostname, create_icontrol(hostname))
    end

    #
    # Create icontrol binding for load balancer
    #
    # @param hostname [String] hostname of load balancer to create binding for
    #
    # @return [Hash] Hash of interfaces from F5::IControl
    #
    #
    def create_icontrol(hostname)
      load_dependencies

      cloud_name = node[:workorder][:cloud][:ciName]
      if node[:workorder][:services].has_key?(:lb)
	      cloud_service = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
      end
      F5::IControl.new(hostname,
                       cloud_service[:username],
                       cloud_service[:password],
                       interfaces).get_interfaces
    end
  end
end
