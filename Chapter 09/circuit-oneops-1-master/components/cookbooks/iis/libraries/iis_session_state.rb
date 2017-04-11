module OO
  class IIS
    class SessionState

      silence_warnings do
        COOKIE_LESS = {
          0 => "UseURI",
          1 => "UseCookies",
          2 => "AutoDetect",
          3 => "UseDeviceProfile"
        }
      end

      def initialize(site_name, web_administration)
        @web_administration = web_administration
        @site_name = site_name
      end

      def cookieless_value
        COOKIE_LESS[@web_administration.session_state_section_for @site_name, "cookieless"]
      end

      def cookieless=(value)
        @web_administration.update_session_state_section_for @site_name, "cookieless", COOKIE_LESS.key(value)
      end

      def cookiename_value
        @web_administration.session_state_section_for @site_name, "cookiename"
      end

      def cookiename=(value)
        @web_administration.update_session_state_section_for @site_name, "cookiename", value
      end

      def time_out_value
        value = @web_administration.session_state_section_for @site_name, "timeout"
        SWbemTimePeriod.convert_swbem_minutes_to_minutes(value)
      end

      def time_out=(value)
        time_out_value = SWbemTimePeriod.convert_minutes_to_swbem_minutes(value)
        @web_administration.update_session_state_section_for @site_name, "timeout", time_out_value
      end

    end
  end
end
