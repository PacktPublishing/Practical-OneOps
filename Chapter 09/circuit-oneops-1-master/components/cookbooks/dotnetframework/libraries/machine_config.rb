require 'rexml/document'
include REXML

module OO
  class Dotnetframework
    class MachineConfig
      def configpath
        `@powershell -NoProfile -ExecutionPolicy Bypass -Command [System.Runtime.InteropServices.RuntimeEnvironment]::SystemConfigurationFile`.strip
      end

      def get_xdoc
        Document.new(File.read(configpath))
      end

      def app_settings_element_exists?
        xpath_exist?(get_xdoc, app_settings_xpath)
      end

      def app_settings_xpath
        "//configuration/appSettings"
      end

      def add_element_xpath
        "//configuration/appSettings/add"
      end

      def configuration_xpath
        "//configuration"
      end

      def xpath_exist?(xdoc, xpath)
        (XPath.match(xdoc, xpath) || []).size > 0
      end

      def add_or_update_app_settings(run_time_context)
        write_to_file = false
        doc = get_xdoc
        doc.elements.each(configuration_xpath) do | configuration |
           configuration.add_element 'appSettings' if !app_settings_element_exists?
           doc.elements.each(app_settings_xpath) do | app_settings |
              add_elements = XPath.match(doc, add_element_xpath)
              run_time_context.each do | key, value |
              add_element_exist = false
              add_elements.each do | add_element |
                if add_element.attributes["key"] == key
                  write_to_file = true if add_element.attributes["value"] != value
                  add_element_exist = true
                  add_element.attributes["value"] = value
                end
              end

              if !add_element_exist
                add_element = app_settings.add_element 'add'
                add_element.attributes["key"] = key
                add_element.attributes["value"] = value
                write_to_file = true
              end
            end
           end
          end

        write_to_file(doc) if write_to_file
        write_to_file
      end

      def write_to_file(doc)
        doc.write(File.open(configpath,"w"),2)
      end
    end
  end
end
