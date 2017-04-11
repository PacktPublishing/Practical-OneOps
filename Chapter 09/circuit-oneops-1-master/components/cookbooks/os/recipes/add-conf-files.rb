# make compute cloud service env_vars available on the system for subsequent workorders
cloud_name = node[:workorder][:cloud][:ciName]
compute_cloud_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
env_vars = {}
oo_vars_conf_content=""

if compute_cloud_service.has_key?("env_vars")
  env_vars = JSON.parse(compute_cloud_service[:env_vars])
end
env_vars_content = ""
env_vars.keys.each do |k|
  env_vars_content += "export #{k}=#{env_vars[k]}\n"
  oo_vars_conf_content += "#{k}=#{env_vars[k]}\n"

end

file "/etc/profile.d/oneops_compute_cloud_service.sh" do
  content env_vars_content
end


if node.workorder.cloud.ciAttributes.has_key?("priority") &&
   node.workorder.cloud.ciAttributes.priority.to_i == 1
   cloud_priority = "primary"
else
  cloud_priority = "secondary"
end


vars =  { 
  :ONEOPS_NSPATH =>  node[:workorder][:rfcCi][:nsPath],
  :ONEOPS_PLATFORM => node[:workorder][:box][:ciName],
  :ONEOPS_ASSEMBLY => node[:workorder][:payLoad][:Assembly][0][:ciName],
  :ONEOPS_ENVIRONMENT => node[:workorder][:payLoad][:Environment][0][:ciName],
  :ONEOPS_ENVPROFILE => node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile],
  :ONEOPS_CI_NAME => node[:workorder][:rfcCi][:ciName],
  :ONEOPS_COMPUTE_CI_ID => node.workorder.payLoad.ManagedVia[0]["ciId"],
  :ONEOPS_CLOUD => node[:workorder][:cloud][:ciName],
  :ONEOPS_CLOUD_AVAIL_ZONE => node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["availability_zone"],
  :ONEOPS_CLOUD_COMPUTE_SERVICE =>node[:workorder][:services][:compute][cloud_name][:ciName],
  :ONEOPS_CLOUD_REGION => compute_cloud_service[:region],
  :ONEOPS_CLOUD_ADMINSTATUS => cloud_priority,
  :ONEOPS_CLOUD_TENANT => compute_cloud_service[:tenant]
}


oo_vars_content = ""
vars.each do |k,v|
  oo_vars_content += "export #{k}=#{v}\n"
  oo_vars_conf_content += "#{k}=#{v}\n"
end


# OS Environment variables.
env_vars = {}
if node.workorder.rfcCi.ciAttributes.has_key?('env_vars') &&
    !node.workorder.rfcCi.ciAttributes.env_vars.empty?
  env_vars = JSON.parse(node.workorder.rfcCi.ciAttributes.env_vars)
end

env_vars.each do |k, v|
  oo_vars_content += "export #{k}=#{v}\n"
  oo_vars_conf_content += "#{k}=#{v}\n"
end

# Get all the env vars
oo_vars_content=oo_vars_content+env_vars_content

file "/etc/profile.d/oneops.sh" do
  content oo_vars_content
end

# ccm requires
file "/etc/profile.d/oneops.conf" do
  content oo_vars_conf_content
end

##For backward compatibilty
link "/etc/oneops" do
  to "/etc/profile.d/oneops.conf"
end

if node.platform != "ubuntu"
  Chef::Log.info("Changing permission for /var/log/messages")
  execute "change_permission" do
      cwd("/var/log/")
      command "chmod a+r messages"
  end
end
