require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

module OO
  class IIS
    class AppPool
      class Recycling
        
        silence_warnings do
          RECYCLING_PROPERTIES = %w{disallow_overlapping_rotation disallow_rotation_on_config_change log_event_on_recycle}
          LOG_EVENT_ON_RECYCLE = {
            1 => "Time",
            2 => "Requests",
            4 => "Schedule",
            8 => "Memory",
            16 => "IsapiUnhealthy",
            32 => "OnDemand",
            64 => "ConfigChange",
            128 => "PrivateMemory",
          }
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}
          RECYCLING_PROPERTIES.each { |method_name| attributes[method_name] = @entity.send(method_name.camelize) }
          attributes["log_event_on_recycle"] = to_humanized_log_event_on_recycle(attributes["log_event_on_recycle"])
          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          attrs["log_event_on_recycle"] = to_wmi_log_event_on_recycle(attrs["log_event_on_recycle"]) if attrs.has_key?("log_event_on_recycle")
          RECYCLING_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).value = attrs[key] if attrs.has_key?(key) }
        end

        def to_humanized_log_event_on_recycle(masks)
          descriptions = []
          LOG_EVENT_ON_RECYCLE.each do |mask, description|
            if (masks & mask) == mask
              descriptions << description
            end
          end
          descriptions
        end

        def to_wmi_log_event_on_recycle(descriptions)
          masks = 0
          LOG_EVENT_ON_RECYCLE.each do |mask, description|
            if descriptions.include?(description)
              masks += mask
            end
          end
          masks
        end
      end
    end
  end
end
