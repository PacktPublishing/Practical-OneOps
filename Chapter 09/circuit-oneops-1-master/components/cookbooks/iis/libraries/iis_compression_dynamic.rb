require_relative "iis_compression_base"

module OO
  class IIS
    class Compression
      class Dynamic < Base
        def initialize(http_compression_section)
          super http_compression_section
        end

        private

        def compression_name
          "Dynamic"
        end
      end
    end
  end
end
