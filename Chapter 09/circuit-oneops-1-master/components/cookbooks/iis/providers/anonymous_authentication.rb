AA_PROPERTIES = ['enabled', 'logon_method', 'username', 'password']

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @anonymous_authentication = OO::IIS.new.anonymous_authentication(new_resource.site_name)
  @web_site = OO::IIS.new.web_site(new_resource.site_name)

  assign_attributes_to_current_resource if iis_available?
end

def resource_needs_change_for?(property)
  return false if new_resource.username == "IUSR" && property == "password"
  new_value = new_resource.send(property)
  current_value = current_resource.send(property)
  (new_value != current_value)
end
private :resource_needs_change_for?

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def assign_attributes_to_current_resource
  attributes = @anonymous_authentication.attributes
  AA_PROPERTIES.each do |property_name|
    current_resource.send(property_name, attributes[property_name])
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
  attributes = Hash.new({})
  modified = false
  if @web_site.exists?
    AA_PROPERTIES.each do |property_name|
      if resource_needs_change_for?(property_name)
        attributes[property_name] = new_resource.send(property_name)
      end
    end

    if not attributes.empty?
      converge_by("configure anonymous authentication properties for website #{new_resource.site_name}") do
        @anonymous_authentication.assign_attributes(attributes)
        modified = true
      end
    end
  end
  new_resource.updated_by_last_action(modified)
end
