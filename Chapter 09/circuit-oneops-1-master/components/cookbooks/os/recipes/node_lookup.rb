rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
server_name = node.workorder.box.ciName+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi["ciId"].to_s
ostype = rfcCi["ciAttributes"]["ostype"]

cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

if ostype == "default-cloud"
  ostype = cloud[:ostype]
end

sizemap = JSON.parse( cloud[:sizemap] )
imagemap = JSON.parse( cloud[:imagemap] )

# size / flavor
size_id = sizemap[rfcCi["ciAttributes"]["size"]]

# image_id
image_id = ''
if !rfcCi[:ciAttributes][:image_id].nil? && !rfcCi[:ciAttributes][:image_id].empty?
  image_id = rfcCi[:ciAttributes][:image_id]
else
  image_id = imagemap[ostype]
end

kp_name = ''
if node.workorder.payLoad.has_key?("SecuredBy")
  env_ci_id = node.workorder.payLoad.Environment[0][:ciId].to_s
  env_ci_name = node.workorder.payLoad.Environment[0][:ciName]
  kp_name = "oneops_key."+ env_ci_id +'.'+ env_ci_name + "." + node.workorder.box.ciId.to_s
else 
  Chef::Log.error("missing SecuredBy payload")
end

# hostname
platform_name = node.workorder.box.ciName
if(platform_name.size > 32)
  platform_name = platform_name.slice(0,32) #truncate to 32 chars
  Chef::Log.info("Truncated platform name to 32 chars : #{platform_name}")
end

vmhostname = platform_name+'-'+node.workorder.cloud.ciId.to_s+'-'+node["workorder"]["rfcCi"]["ciName"].split('-').last.to_i.to_s+'-'+ node["workorder"]["rfcCi"]["ciId"].to_s
node.set[:vmhostname] = vmhostname.downcase
node.set[:server_name] = server_name
node.set[:ostype] = ostype
node.set[:size_id] = size_id
node.set[:image_id] = image_id
node.set[:kp_name] = kp_name
