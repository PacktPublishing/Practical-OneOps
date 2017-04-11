require File.expand_path('../../libraries/models/tenant_model', __FILE__)

Chef::Log.info("Connecting to vCenter " + node[:vsphere][:endpoint].to_s)
Chef::Log.info("Data Center " + node[:vsphere][:datacenter].to_s)
Chef::Log.info("Cluster " + node[:vsphere][:cluster].to_s)
tenant_model = TenantModel.new(node[:vsphere][:endpoint], node[:vsphere][:username], node[:vsphere][:password], node[:vsphere][:vsphere_pubkey])

begin
compute_provider = tenant_model.get_compute_provider
Chef::Log.info("credentials ok")
rescue Exception => e
  Chef::Log.error("credentials bad: #{e.inspect}")
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
