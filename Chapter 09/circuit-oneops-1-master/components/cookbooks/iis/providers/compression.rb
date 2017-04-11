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
  @compression = OO::IIS.new.compression
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.disk_space_limited(@compression.disk_space_limited?)
    @current_resource.max_disk_usage(@compression.max_disk_usage)
    @current_resource.min_file_size_to_compress(@compression.min_file_size_to_compress)
    @current_resource.directory(@compression.directory)
  end
end

def define_resource_requirements
  requirements.assert(:configure) do |a|
    a.assertion { iis_available?  }
    a.failure_message("IIS 7 or a later version needs to be installed / enabled")
    a.whyrun("Would enable IIS 7")
  end
end

action :configure do
  modified = false

  [
    [:disk_space_limited, "Limit to maximum disk usage by IIS compressed files"],
    [:max_disk_usage, "Max disk usage (in megabytes) by compressed files"],
    [:min_file_size_to_compress, "Min file size (in bytes) that will be compressed"],
    [:directory, "Directory where compressed versions of static files are temporarily stored and cached"]
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)

      converge_by("set #{name} to #{desired_value}\n") do
        @compression.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
