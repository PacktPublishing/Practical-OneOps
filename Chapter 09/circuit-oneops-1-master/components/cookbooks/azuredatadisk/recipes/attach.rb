require File.expand_path('../../../azure_base/libraries/utils.rb', __FILE__)

#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

azuredatadisk_datadisk 'data_disk' do
  action :attach
end