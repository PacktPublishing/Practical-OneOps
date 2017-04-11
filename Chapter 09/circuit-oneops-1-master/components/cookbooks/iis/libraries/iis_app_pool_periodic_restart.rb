require "ostruct"
require_relative "ext_kernel"
require_relative "ext_string"

require_relative "swbem_time_period"


module OO
  class IIS
    class AppPool
      class PeriodicRestart
        
        silence_warnings do
          PERIODIC_RESTART_PROPERTIES = %w{memory private_memory requests time}
          SWBEM_DATE_TIME_PERIODIC_RESTART_PROPERTIES = %w{time}
        end

        def initialize(entity)
          @entity = entity || OpenStruct.new
        end

        def attributes
          attributes = {}

          PERIODIC_RESTART_PROPERTIES.each { |method_name| attributes[method_name] = @entity.send(method_name.camelize) }
          SWbemTimePeriod.convert_matching_attributes_from_swbem_date_time(attributes, SWBEM_DATE_TIME_PERIODIC_RESTART_PROPERTIES)
          attributes["schedule"] = @entity.Schedule.each.map { |sch| SWbemTimePeriod.new(sch.Value).to_s }

          OpenStruct.new(attributes)
        end

        def assign_attributes(attrs)
          PERIODIC_RESTART_PROPERTIES.each { |key| @entity.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
          assign_schedule_attributes(attrs.delete("schedule") || [])
        end

        def assign_schedule_attributes(schedule_values)
          schedules = @entity.ChildElements.Item("schedule").Collection
          schedules.Clear
          schedule_values.each do |value|
            schedule = schedules.CreateNewElement("add")
            schedule.Properties.Item("value").Value = value
            schedules.AddElement(schedule)
          end
        end
      end
    end
  end
end
