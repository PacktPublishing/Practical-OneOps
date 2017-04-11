require_relative "iis_compression_static"
require_relative "iis_compression_dynamic"

module OO
  class IIS
    class Compression
      def initialize(web_administration)
        @web_administration = web_administration
      end

      def static
        @static ||= Static.new(@web_administration)
      end

      def dynamic
        @dynamic ||= Dynamic.new(@web_administration)
      end

      def disk_space_limited?
        @web_administration.compression_section_for "DoDiskSpaceLimiting"
      end

      def disk_space_limited=(value)
        @web_administration.update_compression_section_for "DoDiskSpaceLimiting", value
      end

      def max_disk_usage
        @web_administration.compression_section_for "MaxDiskSpaceUsage"
      end

      def max_disk_usage=(value)
        @web_administration.update_compression_section_for "MaxDiskSpaceUsage", value
      end

      def min_file_size_to_compress
        @web_administration.compression_section_for "MinFileSizeForComp"
      end

      def min_file_size_to_compress=(value)
        @web_administration.update_compression_section_for "MinFileSizeForComp", value
      end

      def directory
        @web_administration.compression_section_for "Directory"
      end

      def directory=(value)
        @web_administration.update_compression_section_for "Directory", value
      end
    end
  end
end
