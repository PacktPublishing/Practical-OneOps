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
  @session_state = OO::IIS.new.session_state(new_resource.site_name)
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.cookieless(@session_state.cookieless_value)
    @current_resource.cookiename(@session_state.cookiename_value)
    @current_resource.time_out(@session_state.time_out_value)
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
    [:cookieless, "Session state cookieless"],
    [:cookiename, "Session state cookiename"],
    [:time_out, "Session state timeout"],
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)
      converge_by("#{name} is set to #{desired_value}\n") do
        desired_value =
        @session_state.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
