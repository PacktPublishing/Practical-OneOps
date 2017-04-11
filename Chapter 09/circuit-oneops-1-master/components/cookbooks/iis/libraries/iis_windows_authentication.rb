require_relative 'ext_kernel'

module OO
  class IIS
    class WindowsAuthentication

      silence_warnings do
        WINDOWS_AUTHENTICATION_PROPERTIES = %w{enabled auth_persist_single_request use_kernel_mode}
        WINDOWS_AUTHENTICATION_SECTION = 'system.webServer/security/authentication/windowsAuthentication'
      end

      def initialize(web_administration, site_name)
        @web_administration = web_administration
        @site_name = site_name
      end

      def attributes
        attributes = {}
        @web_administration.site_readable_section_for(WINDOWS_AUTHENTICATION_SECTION, @site_name) do |wa_section|
          WINDOWS_AUTHENTICATION_PROPERTIES.each { |method_name| attributes[method_name] = wa_section.Properties.Item(method_name.camelize).Value }
        end
        OpenStruct.new(attributes)
      end

      def assign_attributes(attrs)
        @web_administration.site_writable_section_for(WINDOWS_AUTHENTICATION_SECTION, @site_name) do |wa_section|
          WINDOWS_AUTHENTICATION_PROPERTIES.each { |key| wa_section.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key) }
        end
      end

    end
  end
end
