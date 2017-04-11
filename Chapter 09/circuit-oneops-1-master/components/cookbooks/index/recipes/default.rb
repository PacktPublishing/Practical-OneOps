[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::IndexHelper }

ci = node.workorder.rfcCi

index_name = ci.ciAttributes.index_name

## Update mappings
mappings = JSON.parse(node.workorder.rfcCi.ciAttributes.json_mappings)
mapping_json = ""
if(!mappings.empty?)
  
  mappings.each do |k,m|
    if(is_valid_json m.to_s)
      if(!mapping_json.empty?)
        mapping_json += ","
      end  
       mapping_json += m
    else
      Chef::Log.error("Invalid mapping json passed for property ::" + k)
      next
    end
   
    index_type = k
    mapping_json = "{ \"#{index_type}\" : { \"properties\" :" + mapping_json + "} } " 
    path = index_name + "/#{index_type}/_mapping"
    
#Chef::Log.info("mapping json:: #{mapping_json}");
#Chef::Log.info("update path:: #{path}");
    
    computes = node.workorder.payLoad.has_key?('RequiresComputes')? 
        node.workorder.payLoad.RequiresComputes : {}
    
    computes.each do |cm|
      unless cm[:ciAttributes][:private_ip].nil?
        host = cm[:ciAttributes][:private_ip]
        update_mapping host, path, mapping_json
      end  
  end
    
  end
  
end  


