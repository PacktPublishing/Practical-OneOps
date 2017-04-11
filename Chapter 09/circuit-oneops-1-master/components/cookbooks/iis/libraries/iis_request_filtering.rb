module OO
  class IIS
    class RequestFiltering

      silence_warnings do
        SECTION = "system.webServer/security/requestFiltering"
      end

      def initialize(web_administration)
        @web_administration = web_administration
      end

      def allow_double_escaping?
        @web_administration.request_filtering_section_for "AllowDoubleEscaping"
      end

      def allow_double_escaping=(value)
        @web_administration.update_request_filtering_section_for "AllowDoubleEscaping", value
      end

      def allow_high_bit_characters?
        @web_administration.request_filtering_section_for "AllowHighBitCharacters"
      end

      def allow_high_bit_characters=(value)
        @web_administration.update_request_filtering_section_for "AllowHighBitCharacters", value
      end

      def verbs
        Hash[@web_administration.nested_request_filtering_section_collection_for("Verbs").each.map { |item| [item.Verb, item.Allowed] }]
      end

      def verbs=(values)
        @web_administration.writable_section_for(SECTION) do |section|
          collection = section.ChildElements.Item("Verbs").Collection
          collection.Clear
          values.each do |name, enable|
            collection.AddElement(new_verb_type_element(collection, name, enable))
          end
        end
      end

      def new_verb_type_element(collection, name, enable)
        collection.CreateNewElement("add").tap do |element|
          element.Properties.Item("verb").Value = name
          element.Properties.Item("allowed").Value = enable
        end
      end

      def max_allowed_content_length_value
        @web_administration.request_filtering_request_limit_section_for "MaxAllowedContentLength"
      end

      def max_allowed_content_length=(value)
        @web_administration.update_request_filtering_request_limit_section_for "MaxAllowedContentLength", value
      end

      def max_url_value
        @web_administration.request_filtering_request_limit_section_for "MaxUrl"
      end

      def max_url=(value)
        @web_administration.update_request_filtering_request_limit_section_for "MaxUrl", value
      end

      def max_query_string_value
        @web_administration.request_filtering_request_limit_section_for "MaxQueryString"
      end

      def max_query_string=(value)
        @web_administration.update_request_filtering_request_limit_section_for "MaxQueryString", value
      end

      def file_extension_allow_unlisted?
        @web_administration.request_filtering_file_extension_section_for "AllowUnlisted"
      end

      def file_extension_allow_unlisted=(value)
        @web_administration.update_request_filtering_file_extension_section_for "AllowUnlisted", value
      end

    end
  end
end
