#
# Cookbook Name:: f5-bigip
# Library:: F5::LoadBalancer::Ltm::Pools::Pool::Member
#

module F5
  class LoadBalancer
    class Ltm
      class Pools
        class Pool
          # Representing an F5 LTM Pool Member
          class Member
            attr_accessor :address, :port, :status

            def initialize(member_hash)
              @address = member_hash['address']
              @port = member_hash['port'].to_s
            end

            def to_hash
              { 'address' => @address, 'port' => @port }
            end
          end
        end
      end
    end
  end
end
