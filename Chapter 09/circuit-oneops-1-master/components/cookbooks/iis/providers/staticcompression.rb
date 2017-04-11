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
  @static_compression = OO::IIS.new.compression.static
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.level(@static_compression.level)
    @current_resource.mime_types(@static_compression.mime_types)
    @current_resource.cpu_usage_to_disable(@static_compression.cpu_usage_to_disable_at)
    @current_resource.cpu_usage_to_reenable(@static_compression.cpu_usage_to_reenable_at)
  end
end

def define_resource_requirements
  requirements.assert(:configure) do |a|
    a.assertion { iis_available?  }
    a.failure_message("IIS 7 or a later version needs to be installed / enabled")
    a.whyrun("Would enable IIS 7")
  end

  requirements.assert(:configure) do |a|
    a.assertion { OO::IIS::Detection.static_compression_enabled?  }
    a.failure_message("IIS 7 static compression needs to be enabled")
    a.whyrun("Would enable static compression for IIS 7")
  end
end

action :configure do
  modified = false

  [
    [:level, "Level for static compression"],
    [:mime_types, "Mime-types setting for static compression"],
    [:cpu_usage_to_disable, "The % CPU utilization above which static compression is disabled"],
    [:cpu_usage_to_reenable, "The % CPU utilization below which disabled static compression is re-enabled"]
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)

      converge_by("set #{name} to #{desired_value}\n") do
        @static_compression.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
