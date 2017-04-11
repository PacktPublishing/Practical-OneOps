PROPERTIES = ["name", "id", "server_auto_start", "bindings", "virtual_directory_path", "virtual_directory_physical_path", "application_path", "application_pool", "certificate_hash", "certificate_store_name" ]

def whyrun_supported?
  true
end

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @web_site = OO::IIS.new.web_site(new_resource.name)
end

def assign_attributes_to_current_resource
  PROPERTIES.each do |property_name|
    value = @web_site.send(property_name)
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
    a.assertion { @web_site.exists? }
    a.failure_message("web site #{new_resource.name} doesn't exist")
    a.whyrun("web site #{new_resource.name} would be created")
  end
end

action :create do
  unless @web_site.exists?
    converge_by("creating web site #{new_resource.name}") do
      status = @web_site.create(get_attributes)
      if status
        @web_site.start
        Chef::Log.info "Created web site #{new_resource.name}"
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.fatal "Failed to create web site #{new_resource.name}"
      end
    end
  end
end

action :update do
  modified = false
  if @web_site.exists?
    if not @web_site.resource_needs_change(get_attributes)
      converge_by("updating web site properties for #{new_resource.name}\n") do
        status = @web_site.update(get_attributes)
        if status
          @web_site.start
          Chef::Log.info "Updated web site #{new_resource.name}"
          modified = true
        else
          Chef::Log.fatal "Failed to update web site #{new_resource.name}"
        end
      end
    end
  end
  new_resource.updated_by_last_action(modified)
end

action :delete do
  if @web_site.exists?
    converge_by("Deleting web site #{new_resource.name}") do
      @web_site.delete
      Chef::Log.info "Deleted web site #{new_resource.name}"
      new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.info "Web site #{new_resource.name} does not exists, nothing to do"
  end
end

def get_attributes
  attributes = Hash.new({})
  PROPERTIES.each do |property_name|
    attributes[property_name] = new_resource.send(property_name)
  end
  attributes
end
