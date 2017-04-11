module OO
  class IIS
    class UrlCompression

      def initialize(web_administration)
        @web_administration = web_administration
      end

      def static_compression_enabled?
        @web_administration.url_compression_section_for "DoStaticCompression"
      end

      def static_compression=(value)
        @web_administration.update_url_compression_section_for "DoStaticCompression", value
      end

      def dynamic_compression_enabled?
        @web_administration.url_compression_section_for "DoDynamicCompression"
      end

      def dynamic_compression=(value)
        @web_administration.update_url_compression_section_for "DoDynamicCompression", value
      end

      def dynamic_compression_before_cache_enabled?
        @web_administration.url_compression_section_for "DynamicCompressionBeforeCache"
      end

      def dynamic_compression_before_cache=(value)
        @web_administration.update_url_compression_section_for "DynamicCompressionBeforeCache", value
      end

    end
  end
end
