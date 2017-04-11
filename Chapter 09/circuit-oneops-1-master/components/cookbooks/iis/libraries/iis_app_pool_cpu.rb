require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPool
      class CPU
        
        silence_warnings do
          CPU_PROPERTIES = %w{action limit reset_interval}
          SWBEM_DATE_TIME_CPU_PROPERTIES = %w{reset_interval}

          ACTIONS = {
            0 => "NoAction",
            1 => "KillW3wp"
          }
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}

          CPU_PROPERTIES.each { |method_name| attributes[method_name] = @entity.send(method_name.camelize) }
          SWbemTimePeriod.convert_matching_attributes_from_swbem_date_time(attributes, SWBEM_DATE_TIME_CPU_PROPERTIES)
          attributes["action"] = ACTIONS[attributes["action"]] if attributes["action"]

          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          CPU_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end
    end
  end
end
