WA_PROPERTIES = ['enabled', 'auth_persist_single_request', 'use_kernel_mode']

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @windows_authentication = OO::IIS.new.windows_authentication(new_resource.site_name)
  @web_site = OO::IIS.new.web_site(new_resource.site_name)

  assign_attributes_to_current_resource if iis_available?
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

def assign_attributes_to_current_resource
  attributes = @windows_authentication.attributes
  WA_PROPERTIES.each do |property_name|
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
    WA_PROPERTIES.each do |property_name|
      if resource_needs_change_for?(property_name)
        attributes[property_name] = new_resource.send(property_name)
      end
    end

    if not attributes.empty?
      converge_by("configure windows authentication properties for website #{new_resource.site_name}") do
        @windows_authentication.assign_attributes(attributes)
        modified = true
      end
    end
  end
  new_resource.updated_by_last_action(modified)
end
