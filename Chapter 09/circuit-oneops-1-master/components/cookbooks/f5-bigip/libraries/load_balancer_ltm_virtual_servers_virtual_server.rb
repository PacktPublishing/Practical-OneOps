#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer::Ltm::VirtualServers::VirtualServer
#

module F5
  class LoadBalancer
    class Ltm
      class VirtualServers
        # VirtualServer from F5
        class VirtualServer
          attr_accessor :name, :destination_address, :destination_port, :destination_wildmask,
                        :default_pool, :type, :protocol, :profiles, :status, :vlans,
                        :snat_type, :snat_pool,
                        :default_persistence_profile, :fallback_persistence_profile, :connection_limit

          attr_writer :rules

          def initialize(name)
            @name = name
          end

          def enabled
            @status['enabled_status'] == 'ENABLED_STATUS_ENABLED'
          end

          #
          # Sort rules in order of priority and return just the name
          #
          # @return <Array[String]>
          #
          def rules
            return [] if @rules.empty?
            @rules.sort_by { |k| k['priority'] }.map { |h| h['rule_name'] }
          end
        end
      end
    end
  end
end
