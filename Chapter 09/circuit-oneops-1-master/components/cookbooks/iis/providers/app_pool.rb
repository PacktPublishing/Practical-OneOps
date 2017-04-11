CONVERSIONS = {
  "name" => ["root", "name"],
  "managed_runtime_version" => ["root", "managed_runtime_version"],
  "managed_pipeline_mode" => ["root", "managed_pipeline_mode"],
  "enable32_bit_app_on_win64" => ["root", "enable32_bit_app_on_win64"],

  "cpu_action" => ["cpu", "action"],
  "cpu_limit" => ["cpu", "limit"],
  "cpu_reset_interval" => ["cpu", "reset_interval"],

  "process_model_idle_timeout" => ["process_model", "idle_timeout"],
  "process_model_max_processes" => ["process_model", "max_processes"],
  "process_model_pinging_enabled" => ["process_model", "pinging_enabled"],
  "process_model_ping_interval" => ["process_model", "ping_interval"],
  "process_model_ping_response_time" => ["process_model", "ping_response_time"],
  "process_model_shutdown_time_limit" => ["process_model", "shutdown_time_limit"],
  "process_model_startup_time_limit" => ["process_model", "startup_time_limit"],
  "process_model_identity_type" => ["process_model", "identity_type"],
  "process_model_user_name" => ["process_model", "user_name"],
  "process_model_password" => ["process_model", "password"],

  "recycling_disallow_overlapping_rotation" => ["recycling", "disallow_overlapping_rotation"],
  "recycling_disallow_rotation_on_config_change" => ["recycling", "disallow_rotation_on_config_change"],
  "recycling_log_event_on_recycle" => ["recycling", "log_event_on_recycle"],

  "recycling_periodic_restart_memory" => ["periodic_restart", "memory"],
  "recycling_periodic_restart_private_memory" => ["periodic_restart", "private_memory"],
  "recycling_periodic_restart_requests" => ["periodic_restart", "requests"],
  "recycling_periodic_restart_schedule" => ["periodic_restart", "schedule"],
  "recycling_periodic_restart_time" => ["periodic_restart", "time"],

  "failure_rapid_fail_protection" => ["failure", "rapid_fail_protection"],
  "failure_rapid_fail_protection_interval" => ["failure", "rapid_fail_protection_interval"],
  "failure_rapid_fail_protection_max_crashes" => ["failure", "rapid_fail_protection_max_crashes"],
}

def whyrun_supported?
  true
end

def resource_needs_change_for?(property)
  new_value = new_resource.send(property)
  current_value = current_resource.send(property)
  (new_value != current_value)
end
private :resource_needs_change_for?

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @app_pool = OO::IIS.new.app_pool(new_resource.name)

  assign_attributes_to_current_resource if iis_available?
end

def assign_attributes_to_current_resource
  CONVERSIONS.each do |property_name, (category, attribute)|
    value = @app_pool.send(category).send(attribute)
    current_resource.send(property_name, value)
  end
end

def define_resource_requirements
  requirements.assert([:create, :update]) do |a|
    a.assertion { iis_available? }
    a.failure_message("IIS 7 or a later version needs to be installed / enabled")
    a.whyrun("Would enable IIS 7")
  end

  requirements.assert(:update) do |a|
    a.assertion { @app_pool.exists? }
    a.failure_message("Application pool #{new_resource.name} doesn't exist")
    a.whyrun("Application pool #{new_resource.name} would be created")
  end
end

action :create do
  unless @app_pool.exists?
    converge_by("create application pool #{new_resource.name}") do
      status = @app_pool.create
      if status
        Chef::Log.info "Created application pool #{new_resource.name}"
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.fatal "Failed to create application pool #{new_resource.name}"
      end
    end
  end
end

action :update do
  if @app_pool.exists?
    messages = []
    attributes = Hash.new({})

    CONVERSIONS.each do |property_name, (category, attribute)|
      new_value = new_resource.send(property_name)
      current_value = current_resource.send(property_name)
      if resource_needs_change_for?(property_name)
        messages << build_message(property_name: property_name, current_value: current_value, new_value: new_value)
        attributes[category][attribute] = new_value
      end
    end

    if not messages.empty?
      converge_by("update application pool properties for #{new_resource.name}\n#{messages.join("\n")}") do
        status = @app_pool.update(attributes)
        if status
          Chef::Log.info "Updated application pool #{new_resource.name}"
          messages.each { |message| Chef::Log.info message }
          new_resource.updated_by_last_action(true)
        else
          Chef::Log.fatal "Failed to update application pool #{new_resource.name}"
        end
      end
    end
  end
end

action :recycle do
  if @app_pool.exists?
    status = @app_pool.status
    if status == 'started'
      @app_pool.recycle
      Chef::Log.info "Recycled application pool #{new_resource.name}"
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.warn "Application pool #{new_resource.name} has not started. Application pool status is #{status}"
    end
  else
    Chef::Log.warn "Application pool #{new_resource.name} does not exist"
  end
end

def build_message(options)
  property_name = options[:property_name]
  current_value = property_name.include?("password") ? "********" : options[:current_value]
  new_value = property_name.include?("password") ? "********" : options[:new_value]

  "#{property_name.gsub('_', ' ')} => from: #{current_value}, to: #{new_value}"
end
