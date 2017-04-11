require File.expand_path('../../libraries/domain_model/tenant', __FILE__)
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
service_lb = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
tenant = Tenant.new(service_lb[:endpoint], service_lb[:tenant], service_lb[:username], service_lb[:password])
tenant.provider = service_lb[:endpoint]

loadbalancer_dao = LoadbalancerDao.new(tenant)
status = loadbalancer_dao.status
if !status
  node.set['status_result'] = 'Error'
end
