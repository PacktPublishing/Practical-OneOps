require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPoolDefaults
      class ProcessModel

        silence_warnings do
          PROCESS_MODEL_PROPERTIES = %w{idle_timeout_action max_processes pinging_enabled identity_type user_name password}

          IDENTITY_TYPE = {
            0 => "LocalSystem",
            1 => "LocalService",
            2 => "NetworkService",
            3 => "SpecificUser",
            4 => "ApplicationPoolIdentity"
          }

          IDLE_TIME_OUT_ACTION = {
            0 => "Terminate",
            1 => "Suspend"
          }
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}

          PROCESS_MODEL_PROPERTIES.each { |key| attributes[key] = @entity.Properties.Item(key.camelize).Value }
          attributes["identity_type"] = IDENTITY_TYPE[attributes["identity_type"]]
          attributes["idle_timeout_action"] = IDLE_TIME_OUT_ACTION[attributes["idle_timeout_action"]]

          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          PROCESS_MODEL_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end
    end
  end
end
