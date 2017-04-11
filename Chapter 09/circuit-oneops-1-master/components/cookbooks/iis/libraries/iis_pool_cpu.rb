require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPoolDefaults
      class CPU

        silence_warnings do
          CPU_PROPERTIES = %w{action limit}

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

          CPU_PROPERTIES.each { |key| attributes[key] = @entity.Properties.Item(key.camelize).Value }
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
