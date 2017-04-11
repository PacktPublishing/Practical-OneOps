module OO
  class IIS
    class LogLocation

      def initialize(web_administration)
        @web_administration = web_administration
      end

      def central_w3c_log_file_directory?
        @web_administration.log_location_section_for("CentralW3CLogFile", "Directory")
      end

      def central_w3c_log_file_directory=(value)
        @web_administration.update_log_location_section_for("CentralW3CLogFile", "Directory", value)
      end

      def central_binary_log_file_directory?
        @web_administration.log_location_section_for("CentralBinaryLogFile", "Directory")
      end

      def central_binary_log_file_directory=(value)
        @web_administration.update_log_location_section_for("CentralBinaryLogFile", "Directory", value)
      end

    end
  end
end
