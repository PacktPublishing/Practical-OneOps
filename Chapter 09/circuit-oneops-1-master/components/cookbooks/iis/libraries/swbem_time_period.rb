require "ostruct"
require_relative "ext_kernel"

module OO
  class SWbemTimePeriod

    #http://regexr.com/3e08s
    silence_warnings do
      EXPRESSION = %r{
        000000
        (?<days>\d\d)
        (?<hours>\d\d)
        (?<minutes>\d\d)
        (?<seconds>\d\d)
        \.(\d+)([+-]*\d\d\d)
      }x
      MINUTE_EXPRESSION = %r{
        0000000000
        (?<minutes>\d\d)
        00
        \.
        000000
        \:
        000
      }x
    end

    def initialize(swbem_time)
      @swbem_time = swbem_time
      parse_values
    end

    def parse_values
      capture = EXPRESSION.match(@swbem_time)
      if capture
        @values = OpenStruct.new({ days: capture["days"], hours: capture["hours"], minutes: capture["minutes"], seconds: capture["seconds"] })
      else
        @values = OpenStruct.new({ days: 0, hours: 0, minutes: 0, seconds: 0 })
      end
    end
    private :parse_values

    def to_s
      @output ||= "%02d:%02d:%02d" % [@values.hours, @values.minutes, @values.seconds]
    end

    class << self
      def convert_matching_attributes_from_swbem_date_time(attributes, restrictions)
        restrictions.each do |attr|
          attributes[attr] = SWbemTimePeriod.new(attributes[attr]).to_s if attributes.has_key?(attr)
        end
      end

      def convert_swbem_minutes_to_minutes(value)
        capture_minutes = MINUTE_EXPRESSION.match(value)
        capture_minutes["minutes"].to_i
      end

      def convert_minutes_to_swbem_minutes(value)
        "0000000000%02d00.000000:000" % value
      end
    end
  end
end
