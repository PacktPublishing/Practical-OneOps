module Couchbase
  module Factory
    class WorkOrderFactory
      attr_reader :node, :component

      def self.init(node)
        @node = node

        createComponent

        @component
      end

      def self.createComponent
        @node.run_list.each { |action|
          if action.name.include?("couchbase")
            @component=Couchbase::Component::CouchbaseComponent.new(@node)
            @component
          elsif action.name.include?("cb_cluster")
              @component=Couchbase::Component::CbClusterComponent.new(@node)
              @component
          elsif action.name.include?("diagnostic_cache")
              @component=Couchbase::Component::DiagnosticCacheComponent.new(@node)
              @component
          end
        }
      end
    end
  end
end

