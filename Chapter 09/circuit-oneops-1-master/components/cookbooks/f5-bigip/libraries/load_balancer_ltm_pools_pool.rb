#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer::Ltm::Pools::Pool
#

module F5
  class LoadBalancer
    class Ltm
      class Pools
        # Representing an F5 LTM Pool
        class Pool
          attr_accessor :name, :lb_method, :monitors, :members, :status

          def initialize(pool_name)
            @name = pool_name
            @members = []
          end
        end
      end
    end
  end
end
