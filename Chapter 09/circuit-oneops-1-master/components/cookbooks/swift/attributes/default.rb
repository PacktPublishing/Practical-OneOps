cloud_name = node.workorder.cloud.ciName
cloud_service = node.workorder.services["filestore"][cloud_name]
default[:swift][:tenant] = cloud_service[:ciAttributes][:tenant]
default[:swift][:endpoint] = cloud_service[:ciAttributes][:endpoint]

if !cloud_service[:ciAttributes][:username].nil? &&
   !cloud_service[:ciAttributes][:username].empty?
     
  username = cloud_service[:ciAttributes][:username]
else
  username = node.workorder.rfcCi.ciAttributes[:username]
end
if !cloud_service[:ciAttributes][:password].nil? &&
   !cloud_service[:ciAttributes][:password].empty?
     
  password = cloud_service[:ciAttributes][:password]
else
  password = node.workorder.rfcCi.ciAttributes[:password]
end

default[:swift][:username] = username
default[:swift][:password] = password
default[:swift][:authstrategy] = cloud_service[:ciAttributes][:authstrategy]
default[:swift][:homepath]= '/etc'
