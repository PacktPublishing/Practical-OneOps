require_relative "ext_kernel"

module OO
  class IIS
    class Compression
      class Base

        silence_warnings do
          SECTION = "system.webServer/httpCompression"
        end

        def initialize(web_administration)
          @web_administration = web_administration
        end

        def enabled?
          @web_administration.compression_section_item_for "Do#{compression_name}Compression"
        end

        def level
          @web_administration.compression_section_item_for "#{compression_name}CompressionLevel"
        end

        def level=(value)
          @web_administration.update_compression_section_item_for "#{compression_name}CompressionLevel", value
        end

        def mime_types
          Hash[@web_administration.nested_compression_section_collection_for("#{compression_name}Types").each.map { |item| [item.MimeType, item.Enabled] }]
        end

        def mime_types=(values)
          @web_administration.writable_section_for(SECTION) do |section|
            collection = section.ChildElements.Item("#{compression_name}Types").Collection
            collection.Clear

            values.each do |name, status|
              collection.AddElement(new_mime_type_element(collection, name, status))
            end
          end
        end


        def cpu_usage_to_disable_at
          @web_administration.compression_section_for "#{compression_name}CompressionDisableCpuUsage"
        end

        def cpu_usage_to_disable_at=(value)
          @web_administration.update_compression_section_for "#{compression_name}CompressionDisableCpuUsage", value
        end

        def cpu_usage_to_reenable_at
          @web_administration.compression_section_for "#{compression_name}CompressionEnableCpuUsage"
        end

        def cpu_usage_to_reenable_at=(value)
          @web_administration.update_compression_section_for "#{compression_name}CompressionEnableCpuUsage", value
        end

        alias_method :cpu_usage_to_disable, :cpu_usage_to_disable_at
        alias_method :cpu_usage_to_disable=, :cpu_usage_to_disable_at=
        alias_method :cpu_usage_to_reenable, :cpu_usage_to_reenable_at
        alias_method :cpu_usage_to_reenable=, :cpu_usage_to_reenable_at=


        private

        def compression_name
          # Set appropriate compression type - Static or Dynamic
        end

        def new_mime_type_element(collection, name, status)
          collection.CreateNewElement("add").tap do |element|
            element.Properties.Item("MimeType").Value = name
            element.Properties.Item("Enabled").Value = status
          end
        end
      end
    end
  end
end
