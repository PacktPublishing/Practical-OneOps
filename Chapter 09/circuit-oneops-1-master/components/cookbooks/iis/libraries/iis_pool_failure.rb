require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"


module OO
  class IIS
    class AppPoolDefaults
      class Failure

        silence_warnings do
          FAILURE_PROPERTIES = %w{rapid_fail_protection rapid_fail_protection_interval}
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}
          FAILURE_PROPERTIES.each { |key| attributes[key] = @entity.Properties.Item(key.camelize).Value }
          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          FAILURE_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end
    end
  end
end
