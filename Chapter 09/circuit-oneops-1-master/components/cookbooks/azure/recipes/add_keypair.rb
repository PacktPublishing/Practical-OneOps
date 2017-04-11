#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])

# create the resource group
azure_resource_group 'resource group' do
  node node
  action :create
end

# create the availability set
azure_availability_set 'availability set' do
  node node
  action :create
end

OOLog.info('Exiting add keypair')
