require 'azure'

os_disk_blobname = (node['vhd_uri'].split("/").last)
OOLog.info("Deleting os_disk : #{os_disk_blobname}")
dd_manager = Datadisk.new(node)
dd_manager.delete_disk_by_name(os_disk_blobname)

if node['datadisk_uri'] != nil
data_disk_blobname = (node['datadisk_uri'].split("/").last)

if data_disk_blobname.include?(node['storage_account'])
    OOLog.info("Deleting data_disk : #{data_disk_blobname}")
    dd_manager.delete_disk_by_name(data_disk_blobname)    
  end
end