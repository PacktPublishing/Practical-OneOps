def whyrun_supported?
  true
end

def resource_needs_change_for?(property)
  new_resource.send(property) != current_resource.send(property)
end
private :resource_needs_change_for?

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def load_current_resource
  @dynamic_compression = OO::IIS.new.compression.dynamic
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.level(@dynamic_compression.level)
    @current_resource.mime_types(@dynamic_compression.mime_types)
    @current_resource.cpu_usage_to_disable(@dynamic_compression.cpu_usage_to_disable_at)
    @current_resource.cpu_usage_to_reenable(@dynamic_compression.cpu_usage_to_reenable_at)
  end
end

def define_resource_requirements
  requirements.assert(:configure) do |a|
    a.assertion { iis_available?  }
    a.failure_message("IIS 7 or a later version needs to be installed / enabled")
    a.whyrun("Would enable IIS 7")
  end

  requirements.assert(:configure) do |a|
    a.assertion { OO::IIS::Detection.dynamic_compression_enabled?  }
    a.failure_message("IIS 7 dynamic compression needs to be enabled")
    a.whyrun("Would enable dynamic compression for IIS 7")
  end
end

action :configure do
  modified = false

  [
    [:level, "Level for dynamic compression"],
    [:mime_types, "Mime-types setting for dynamic compression"],
    [:cpu_usage_to_disable, "The % CPU utilization above which dynamic compression is disabled"],
    [:cpu_usage_to_reenable, "The % CPU utilization below which disabled dynamic compression is re-enabled"]
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)

      converge_by("set #{name} to #{desired_value}\n") do
        @dynamic_compression.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
