require_relative "ext_kernel"

module OO
  class IIS
    class WebAdministration

      module Logger
        class Default
          def log(message)
            puts message
          end
        end

        class Blank
          def log(message)
            #no-op
          end
        end
      end

      silence_warnings do
        WEB_ADMINISTRATION_ROOT = 'winmgmts:\\root\WebAdministration'
        CREATEONLY = 2
        UPDATEONLY = 1
        APPHOST_PATH = "MACHINE/WEBROOT/APPHOST"
        APPLICATION = "Application"
      end

      class << self
        def log(message)
          @logger ||= Logger::Default.new
          @logger.log(message)
        end

        def logger=(item)
          @logger = item
        end
      end

      def initialize
        require 'win32ole'
      end

      def wmiroot
        @wmiroot ||= WIN32OLE.connect(WEB_ADMINISTRATION_ROOT)
      end
      private :wmiroot

      def website
        @website ||= wmiroot.Get(APPLICATION)
      end
      private :website

      def http_compression_section
        @http_compression_section ||= wmiroot.Get("HttpCompressionSection.Path='#{APPHOST_PATH}',Location=''")
      end
      private :http_compression_section

      def url_compression_section
        @url_compression_section ||= wmiroot.Get("UrlCompressionSection.Path='#{APPHOST_PATH}',Location=''")
      end
      private :url_compression_section

      def isapi_cgi_restriction_section
        @isapi_cgi_estriction_section ||= wmiroot.Get("IsapiCgiRestrictionSection.Path='#{APPHOST_PATH}',Location=''")
      end
      private :isapi_cgi_restriction_section

      def request_filtering_section
        @request_filtering_section ||= wmiroot.Get("RequestFilteringSection.Path='#{APPHOST_PATH}',Location=''")
      end
      private :request_filtering_section

      def log_location_section
        @log_location_section ||= wmiroot.Get("LogSection.Path='#{APPHOST_PATH}',Location=''")
      end
      private :log_location_section

      def session_state_section(site_name)
        @session_state_section ||= wmiroot.Get("SessionStateSection.Path='#{APPHOST_PATH}/#{site_name}',Location=''")
      end
      private :session_state_section

      def reload
        @wmiroot = @http_compression_section = @url_compression_section = @isapi_cgi_estriction_section = @request_filtering_section = @log_location_section = @session_state_section = nil
      end
      private :reload

      def get(name)
        wmiroot.Get(name)
      rescue WIN32OLERuntimeError => ex
        nil
      end

      def find(class_name, entity_name, &block)
        find!(class_name, entity_name, &block)
      rescue WIN32OLERuntimeError => ex
        nil
      end

      def find!(class_name, entity_name, &block)
        wmiroot.Get("#{class_name}.Name='#{entity_name}'").tap do |entity|
          yield entity if block_given?
        end
      end

      def perform(&block)
        begin
          yield
          reload
          true
        rescue WIN32OLERuntimeError => ex
          self.class.log ex.inspect
          false
        end
      end

      def perform_reportable_action(object, action, &block)
        return false unless object

        result = false
        object.tap do |entity|
          begin
            yield entity if block_given?
            entity.send(*action)
            result = true
          rescue WIN32OLERuntimeError => ex
            self.class.log ex.inspect
          end
        end
        result
      end
      private :perform_reportable_action

      def delete(class_name, entity_name)
        perform_reportable_action(find(class_name, entity_name), [:Delete_])
      end

      def compression_section_for(attribute)
        http_compression_section.send(attribute)
      end

      def update_compression_section_for(attribute, value)
        http_compression_section.send("#{attribute}=", value)
        http_compression_section.Put_(UPDATEONLY)
        reload
      end

      def url_compression_section_for(attribute)
        url_compression_section.send(attribute)
      end

      def update_url_compression_section_for(attribute, value)
        url_compression_section.send("#{attribute}=", value)
        url_compression_section.Put_(UPDATEONLY)
        reload
      end

      def isapi_cgi_restriction_section_for(attribute)
        isapi_cgi_restriction_section.send(attribute)
      end

      def update_isapi_cgi_restriction_section_for(attribute, value)
        isapi_cgi_restriction_section.send("#{attribute}=", value)
        isapi_cgi_restriction_section.Put_(UPDATEONLY)
        reload
      end

      def request_filtering_section_for(attribute)
        request_filtering_section.send(attribute)
      end

      def update_request_filtering_section_for(attribute, value)
        request_filtering_section.send("#{attribute}=", value)
        request_filtering_section.Put_(UPDATEONLY)
        reload
      end

      def request_limit_element
        request_filtering_section.RequestLimits
      end

      def request_filtering_request_limit_section_for(attribute)
        request_limit_element.send(attribute)
      end

      def update_request_filtering_request_limit_section_for(attribute, value)
        request_limit_element.send("#{attribute}=", value)
        request_filtering_section.Put_(UPDATEONLY)
        reload
      end

      def file_extension_element
        request_filtering_section.FileExtensions
      end

      def request_filtering_file_extension_section_for(attribute)
        file_extension_element.send(attribute)
      end

      def update_request_filtering_file_extension_section_for(attribute, value)
        file_extension_element.send("#{attribute}=", value)
        request_filtering_section.Put_(UPDATEONLY)
        reload
      end

      def log_location_section_for(element, attribute)
        log_location_section.send(element).send(attribute)
      end

      def update_log_location_section_for(element, attribute, value)
        log_location_section.send(element).send("#{attribute}=", value)
        log_location_section.Put_(UPDATEONLY)
        reload
      end

      def nested_request_filtering_section_collection_for(attribute)
        request_filtering_section.send(attribute).send(attribute)
      end

      def compression_section_item_for(attribute)
        http_compression_section.HttpCompression.each.map { |item| item.send(attribute) }.uniq.first
      end

      def update_compression_section_item_for(attribute, value)
        http_compression_section.HttpCompression.each { |item| item.send("#{attribute}=", value) }
        http_compression_section.Put_(UPDATEONLY)
        reload
      end

      def nested_compression_section_collection_for(attribute)
        http_compression_section.send(attribute).send(attribute)
      end

      def session_state_section_for(site_name, attribute)
        session_state = session_state_section(site_name)
        if attribute != "timeout"
          session_state.send(attribute)
        else
          session_state.timeout
        end
      end

      def update_session_state_section_for(site_name, attribute, value)
        session_state = session_state_section(site_name)
        session_state.send("#{attribute}=", value)
        session_state.Put_(UPDATEONLY)
        reload
      end

      def writable_section_for(section, &block)
        admin_manager = WIN32OLE.new("Microsoft.ApplicationHost.WritableAdminManager")
        admin_manager.CommitPath = APPHOST_PATH
        section = admin_manager.GetAdminSection(section, APPHOST_PATH)
        yield section

        admin_manager.CommitChanges
        reload
      end

      def readable_section_for(section, &block)
        admin_manager = WIN32OLE.new("Microsoft.ApplicationHost.WritableAdminManager")
        admin_manager.CommitPath = APPHOST_PATH
        section = admin_manager.GetAdminSection(section, APPHOST_PATH)
        yield section

      end

      def site_writable_section_for(section, site_name, &block)
        admin_manager = WIN32OLE.new("Microsoft.ApplicationHost.WritableAdminManager")
        site_path = "#{APPHOST_PATH}/#{site_name}"
        section = admin_manager.GetAdminSection(section, site_path)
        yield section

        admin_manager.CommitChanges
        reload
      end

      def site_readable_section_for(section, site_name, &block)
        admin_manager = WIN32OLE.new("Microsoft.ApplicationHost.WritableAdminManager")
        admin_manager.CommitPath = APPHOST_PATH
        site_path = "#{APPHOST_PATH}/#{site_name}"
        section = admin_manager.GetAdminSection(section, site_path)
        yield section

      end

    end
  end
end
