
ci = node.workorder.rfcCi

attrs = ci[:ciAttributes]

token = ""
if attrs.has_key?("token") &&
   !attrs[:token].empty?

  token = attrs[:token]
  Chef::Log.info("using token from rfcCi: #{token}")
end


if token.empty?
  
  ring_computes = node.workorder.payLoad["RequiresComputes"]
  
  ruby_block 'get ' do
    block do   
        
    end
  end
  
  other_member_ip = ""
  ring_computes.each do |compute|
    compute_index = compute[:ciName].split("-").last
    next if node_index == compute_index
    
    if compute[:ciAttributes].has_key?("private_ip")
      
      other_member_ip = compute[:ciAttribtues][:private_ip]
      break
    end
  end
  
end  
