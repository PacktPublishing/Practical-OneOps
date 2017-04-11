module OO
  class IIS
    class MimeMapping

      silence_warnings do
        MIME_MAPPING_SECTION = "system.webServer/staticContent"
      end

      def initialize(web_administration, site_name)
        @web_administration = web_administration
        @site_name = site_name
      end

      def mime_types
        current_mime_types = []
        @web_administration.site_readable_section_for(MIME_MAPPING_SECTION, @site_name) do |mm_section|
          mime_type_collection = mm_section.Collection
          (0..(mime_type_collection.Count-1)).each do |i|
            file_extension = mime_type_collection.Item(i).GetPropertyByName('FileExtension').Value
            mime_type = mime_type_collection.Item(i).GetPropertyByName('MimeType').Value
            current_mime_types << {'file_extension' => "#{file_extension}", 'mime_type' => "#{mime_type}"}
          end
        end
        current_mime_types
      end

      def add_mime_type(new_mime_type)
        @web_administration.site_writable_section_for(MIME_MAPPING_SECTION, @site_name) do |mm_section|
          mime_type_collection = mm_section.Collection
          mime_map_element = mime_type_collection.CreateNewElement("mimeMap")
          mime_map_element.Properties.Item("FileExtension").Value = new_mime_type["file_extension"]
          mime_map_element.Properties.Item("MimeType").Value = new_mime_type["mime_type"]
          mime_type_collection.AddElement(mime_map_element)
        end
      end

    end
  end
end
