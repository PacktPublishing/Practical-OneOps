cloud_name = node[:workorder][:cloud][:ciName]
compute_cloud_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

if compute_cloud_service.has_key?("env_vars")
  env_vars = JSON.parse(compute_cloud_service[:env_vars])
end

runtime_context = {
  'Cloud'   =>  node[:workorder][:cloud][:ciName],
  'Env'     =>  node[:workorder][:payLoad][:Environment][0][:ciName],
  'EnvType' =>  node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile],
}

runtime_context.tap do | env_vars_hash |
  env_vars_hash['CloudDc'] = env_vars['DATACENTER'] if env_vars.has_key?('DATACENTER')
end


dotnetframework_machine_config 'add runtime context' do
  action :add_or_update
  run_time_context runtime_context
end
