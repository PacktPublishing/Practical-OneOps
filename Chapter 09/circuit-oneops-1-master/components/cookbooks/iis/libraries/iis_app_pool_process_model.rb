require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPool
      class ProcessModel
        
        silence_warnings do
          PROCESS_MODEL_PROPERTIES = %w{idle_timeout max_processes pinging_enabled ping_interval ping_response_time shutdown_time_limit startup_time_limit identity_type user_name password}
          SWBEM_DATE_TIME_PROCESS_MODEL_PROPERTIES = %w{idle_timeout ping_interval ping_response_time shutdown_time_limit startup_time_limit}

          IDENTITY_TYPE = {
            0 => "LocalSystem",
            1 => "LocalService",
            2 => "NetworkService",
            3 => "SpecificUser",
            4 => "ApplicationPoolIdentity"
          }
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}

          PROCESS_MODEL_PROPERTIES.each { |method_name| attributes[method_name] = @entity.send(method_name.camelize) }
          SWbemTimePeriod.convert_matching_attributes_from_swbem_date_time(attributes, SWBEM_DATE_TIME_PROCESS_MODEL_PROPERTIES)
          attributes["identity_type"] = IDENTITY_TYPE[attributes["identity_type"]]

          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          PROCESS_MODEL_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end
    end
  end
end
