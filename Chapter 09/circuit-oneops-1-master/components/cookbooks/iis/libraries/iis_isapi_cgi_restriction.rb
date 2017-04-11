module OO
  class IIS
    class ISAPICGIRestrication

      def initialize(web_administration)
        @web_administration = web_administration
      end

      def not_listed_isapis_allowed?
        @web_administration.isapi_cgi_restriction_section_for "NotListedIsapisAllowed"
      end

      def not_listed_isapis_allowed=(value)
        @web_administration.update_isapi_cgi_restriction_section_for "NotListedIsapisAllowed", value
      end

      def not_listed_cgis_allowed?
        @web_administration.isapi_cgi_restriction_section_for "NotListedCgisAllowed"
      end

      def not_listed_cgis_allowed=(value)
        @web_administration.update_isapi_cgi_restriction_section_for "NotListedCgisAllowed", value
      end

    end
  end
end
