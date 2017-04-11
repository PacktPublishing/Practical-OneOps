require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
container = node[:workorder][:rfcCi]

namespace = node.workorder.rfcCi.nsPath.split("/")[1..3].join("-").to_s

ruby_block "delete container #{node[:container_name]}" do
  block do
    delete_deployment = "kubectl delete deployment #{node[:container_name]} -n #{namespace} 2>&1"
    Chef::Log.info(delete_deployment)
    result = `#{delete_deployment}`
    if $?.success?
      Chef::Log.info(result)
    else
      raise result
    end
  end
end

ruby_block "delete service #{node[:container_name]}" do
  block do
    delete_service = "kubectl delete service #{node[:container_name]} -n #{namespace} 2>&1"
    Chef::Log.info(delete_service)
    result = `#{delete_service}`
    if $?.success?
      Chef::Log.info(result)
    else
      raise result
    end
  end
end
