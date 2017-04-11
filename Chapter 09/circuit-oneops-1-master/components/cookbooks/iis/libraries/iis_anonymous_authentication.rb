require_relative 'ext_kernel'

module OO
  class IIS
    class AnonymousAuthentication

      silence_warnings do
        ANONYMOUS_AUTHENTICATION_PROPERTIES = %w{enabled logon_method username password}
        ANONYMOUS_AUTHENTICATION_SECTION = 'system.webServer/security/authentication/anonymousAuthentication'

        LOGON_METHOD = {
          'Interactive' => 0,
          'Batch' => 1,
          'Network' => 2,
          'ClearText' => 3
        }
      end

      def initialize(web_administration, site_name)
        @web_administration = web_administration
        @site_name = site_name
      end

      def attributes
        attributes = {}
        @web_administration.site_readable_section_for(ANONYMOUS_AUTHENTICATION_SECTION, @site_name) do |aa_section|
          ANONYMOUS_AUTHENTICATION_PROPERTIES.each do |method_name|
            attributes[method_name] = aa_section.Properties.Item(method_name.camelize).Value
          end
        end
        attributes['logon_method'] = to_humanized_logon_method(attributes['logon_method'])

        OpenStruct.new(attributes)
      end

      def assign_attributes(attrs)
        @web_administration.site_writable_section_for(ANONYMOUS_AUTHENTICATION_SECTION, @site_name) do |aa_section|
          attrs['logon_method'] = to_wmi_logon_method(attrs['logon_method']) if attrs.has_key?('logon_method')
          ANONYMOUS_AUTHENTICATION_PROPERTIES.each do |key|
            aa_section.Properties.Item(key.camelize).Value = attrs[key] if attrs.has_key?(key)
          end
        end
      end

      private

      def to_humanized_logon_method(method)
        LOGON_METHOD.key(method)
      end

      def to_wmi_logon_method(method)
        LOGON_METHOD[method]
      end

    end
  end
end
