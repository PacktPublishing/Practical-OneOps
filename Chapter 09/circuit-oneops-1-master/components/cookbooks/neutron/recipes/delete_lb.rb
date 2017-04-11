require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/loadbalancer_manager', __FILE__)

cloud_name = node[:workorder][:cloud][:ciName]
service_lb_attributes = node[:workorder][:services][:lb][cloud_name][:ciAttributes]
tenant = TenantModel.new(service_lb_attributes[:endpoint],service_lb_attributes[:tenant],
                         service_lb_attributes[:username],service_lb_attributes[:password])
include_recipe "neutron::build_lb_name"

lb_name = node[:lb_name]

lb_manager = LoadbalancerManager.new(tenant)
Chef::Log.info("Deleting Loadbalancer..." + lb_name)
start_time = Time.now
Chef::Log.info("start time " + start_time.to_s)
lb_manager.delete_loadbalancer(lb_name)
Chef::Log.info("end time " + Time.now.to_s)
total_time = Time.now - start_time
Chef::Log.info("Total time to delete " + total_time.to_s)
Chef::Log.info("Exiting neutron-lbaas delete recipe.")
