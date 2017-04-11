require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPoolDefaults
      class PeriodicRestart

        silence_warnings do
          PERIODIC_RESTART_PROPERTIES = %w{memory private_memory requests}
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}
          PERIODIC_RESTART_PROPERTIES.each { |key| attributes[key] = @entity.Properties.Item(key.camelize).Value }
          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          PERIODIC_RESTART_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end

      end
    end
  end
end
