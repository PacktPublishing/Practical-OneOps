require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
container_service = node[:workorder][:services][:container][cloud_name][:ciAttributes]
set = node[:workorder][:rfcCi]

namespace = node.workorder.rfcCi.nsPath.split("/")[1..3].join("-").to_s

#
# 1. construct the kubectl command arguments to scale deployment
# kubectl scale deployment <container_name> --replicas=N
#

ruby_block "scale #{node[:container_name]}" do
  block do
    replicas = set[:ciAttributes][:replicas]
    kubectl_scale = "kubectl scale deployment #{node[:container_name]} -n #{namespace} --replicas=#{replicas} 2>&1"
    Chef::Log.info(kubectl_scale)
    result = `#{kubectl_scale}`
    if $?.success?
      Chef::Log.info(result)
    else
      raise result
    end
  end
end

#
# 2. wait for the status to be rolled out
#
ruby_block "deployment #{node[:container_name]} status" do
  block do
    Chef::Log.info("kubectl rollout status deployment #{node[:container_name]} -n #{namespace} 2>&1`")
    result = `kubectl rollout status deployment #{node[:container_name]} -n #{namespace} 2>&1`
    if $?.success?
      Chef::Log.info(result)
    else
      raise result
    end
  end
end
