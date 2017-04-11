require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

module OO
  class IIS
    class AppPoolDefaults
      class Root
        silence_warnings do
          PROPERTIES = %w{managed_runtime_version managed_pipeline_mode enable32_bit_app_on_win64}

          PIPELINE_MODES = {
            :integrated => 0,
            :classic => 1
          }
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}
          PROPERTIES.each { |key| attributes[key] = @entity.Properties.Item(key.camelize).Value }
          attributes["managed_pipeline_mode"] = to_humanized_managed_pipeline_mode(attributes["managed_pipeline_mode"])
          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          attrs["managed_pipeline_mode"] = to_wmi_managed_pipeline_mode(attrs["managed_pipeline_mode"]) if attrs.has_key?("managed_pipeline_mode")
          PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end

        private

        def to_humanized_managed_pipeline_mode(mode)
          PIPELINE_MODES.key(mode)
        end

        def to_wmi_managed_pipeline_mode(mode)
          PIPELINE_MODES[mode]
        end
      end
    end
  end
end
