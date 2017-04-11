require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"


module OO
  class IIS
    class AppPool
      class Failure
        
        silence_warnings do
          FAILURE_PROPERTIES = %w{rapid_fail_protection rapid_fail_protection_interval rapid_fail_protection_max_crashes}
          SWBEM_DATE_TIME_FAILURE_PROPERTIES = %w{rapid_fail_protection_interval}
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}
          FAILURE_PROPERTIES.each { |method_name| attributes[method_name] = @entity.send(method_name.camelize) }
          SWbemTimePeriod.convert_matching_attributes_from_swbem_date_time(attributes, SWBEM_DATE_TIME_FAILURE_PROPERTIES)
          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          FAILURE_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end
    end
  end
end
