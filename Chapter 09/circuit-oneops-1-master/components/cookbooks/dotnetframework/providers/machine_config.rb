def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @machine_config = OO::Dotnetframework::MachineConfig.new
end

action :add_or_update do
  status = @machine_config.add_or_update_app_settings(new_resource.run_time_context)
  if status
    new_resource.updated_by_last_action(true)
    Chef::Log.info "Runtime context has been added"
  else
    Chef::Log.info "Runtime context is already up to date"
  end
end
