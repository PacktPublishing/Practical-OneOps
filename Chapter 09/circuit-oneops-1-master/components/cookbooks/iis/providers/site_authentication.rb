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
  @request_filtering = OO::IIS.new.authentication
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.central_w3c_log_file_directory(@request_filtering.central_w3c_log_file_directory?)
    @current_resource.central_binary_log_file_directory(@request_filtering.central_binary_log_file_directory?)
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
    [:central_w3c_log_file_directory, "Central W3C log file location"],
    [:central_binary_log_file_directory, "Central binary log file location"],
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)

      converge_by("#{name} is set to #{desired_value}\n") do
        @request_filtering.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
