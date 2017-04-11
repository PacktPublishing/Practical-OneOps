#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

azuredatadisk_datadisk 'create vhd' do
  action :create
end
