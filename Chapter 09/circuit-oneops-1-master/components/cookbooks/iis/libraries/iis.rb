require_relative "iis_web_administration"
require_relative "iis_compression"

module OO
  class IIS
    def initialize
      @web_administration = OO::IIS::WebAdministration.new
    end

    def app_pool(name)
      OO::IIS::AppPool.new(@web_administration, name)
    end

    def app_pool_defaults
      OO::IIS::AppPoolDefaults.new(@web_administration)
    end

    def web_site(name)
      OO::IIS::WebSite.new(@web_administration, name)
    end

    def compression
      @compression ||= OO::IIS::Compression.new(@web_administration)
    end

    def static_compression
      @static_compression ||= compression.static
    end

    def dynamic_compression
      @dynamic_compression ||= compression.dynamic
    end

    def url_compression
      @url_compression ||= OO::IIS::UrlCompression.new(@web_administration)
    end

    def isapi_cgi_restriction
      @isapi_cgi_restriction ||= OO::IIS::ISAPICGIRestrication.new(@web_administration)
    end

    def request_filtering
      @request_filtering ||= OO::IIS::RequestFiltering.new(@web_administration)
    end

    def log_location
      @log_location ||= OO::IIS::LogLocation.new(@web_administration)
    end

    def session_state(site_name)
      @session_state ||= OO::IIS::SessionState.new(site_name, @web_administration)
    end

    def windows_authentication(site_name)
      @windows_authentication ||= OO::IIS::WindowsAuthentication.new(@web_administration, site_name)
    end

    def anonymous_authentication(site_name)
      @anonymous_authentication ||= OO::IIS::AnonymousAuthentication.new(@web_administration, site_name)
    end

    def mime_mapping(site_name)
      @mime_mapping ||= OO::IIS::MimeMapping.new(@web_administration, site_name)
    end

  end
end
