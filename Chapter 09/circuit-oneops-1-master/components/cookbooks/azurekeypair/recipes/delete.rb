
#set the proxy if it exists as a cloud var
Utils.set_proxy(node[:workorder][:payLoad][:OO_CLOUD_VARS])
Chef::Log.info("Action is " +node.workorder.rfcCi.rfcAction )
if node.workorder.rfcCi.rfcAction != "update" || node.workorder.rfcCi.rfcAction != "replace"
  # create the resource group
  azurekeypair_resource_group 'Resource Group' do
    action :destroy
  end
end


OOLog.info('Exiting delete keypair')
