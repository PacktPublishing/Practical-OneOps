module Couchbase
  module Component
    class DiagnosticCacheComponent < Couchbase::Component::CbClusterComponent

      def initialize(data)
        @data = data

        # dc is dynamic payload defined in the pack to get the resources
        if (@data.workorder.payLoad.has_key?('dc'))
          dc = @data.workorder.payLoad.dc.select { |c| c['ciClassName'].split('.').last == 'Couchbase' }.first
  
          attributes = dc["ciAttributes"]
          @username = attributes["adminuser"]
          @password = attributes["adminpassword"]
          @port = attributes["port"]
            
        else
          raise "Missing dc from payLoad"
        end

        
        # cb_cmp is dynamic payload defined in the pack to get the computes in the ring
        if (@data.workorder.payLoad.has_key?('cb_cmp'))
          @nodes=@data.workorder.payLoad.cb_cmp
        else
          @nodes=@data.workorder.payLoad.ManagedVia
        end
        
        @nodes.each { |node|
          if node['ciAttributes'].has_key?("private_ip")
            ip=node['ciAttributes']["private_ip"]
            begin
              @cluster = Couchbase::CouchbaseCluster.new(ip, @username, @password)
              if @cluster.list_nodes.length > 0
                break
              end
            rescue Exception => e
              Chef::Log.warn "NODE:#{ip} #{e.message}"
            end

          end
        }
      end

      def execute

        @data.run_list.each { |action|
          if action.name == "diagnostic_cache::repair"
            repair_diagnostic_cache
          else
            Chef::Log.warn "unknown action #{action}"
          end
        }

      end
      
      def repair_diagnostic_cache
        Couchbase::CouchbaseProcess.new.start()
        repair
      end
    end
  end
end
