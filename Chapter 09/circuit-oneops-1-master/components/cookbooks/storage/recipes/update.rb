Chef::Log.info("Storage Update .......")

v_device_map = node.workorder.rfcCi.ciAttributes["device_map"]
cloud_name = node[:workorder][:cloud][:ciName]
storage_provider = node[:workorder][:services][:storage][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
Chef::Log.info("Device Map : <"+v_device_map.to_s+">")

 #If Storage is not Allocated the Only Call Storage Add else Do Nothing
if v_device_map.nil?
  include_recipe 'storage::add'
else
  Chef::Log.info("device map not nil")
  if storage_provider =~ /cinder/
    include_recipe 'storage::add'
  else
    Chef::Log.info("Storage volume extension not supported")
  end
end
