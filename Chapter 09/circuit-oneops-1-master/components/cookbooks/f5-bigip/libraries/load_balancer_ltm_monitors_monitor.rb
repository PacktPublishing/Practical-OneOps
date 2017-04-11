#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer::Ltm::Monitors::Monitor
#
require 'forwardable'

module F5
  class LoadBalancer
    class Ltm
      class Monitors
        # Monitor template from F5
        class Monitor
          include ::Enumerable
          extend ::Forwardable

          attr_reader :name, :type

          attr_accessor :parent, :interval, :timeout, :directly_usable,
                        :dest_addr_type, :dest_addr_ip, :dest_addr_port

          def_delegators :@data, :[], :[]=, :keys

          def initialize(monitor_soap_map)
            @name = monitor_soap_map['template_name']
            @type = monitor_soap_map['template_type']
            @data = {}
          end

          def user_values
            @data
          end
        end
      end
    end
  end
end
