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
  @url_compression = OO::IIS.new.url_compression
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.static_compression(@url_compression.static_compression_enabled?)
    @current_resource.dynamic_compression(@url_compression.dynamic_compression_enabled?)
    @current_resource.dynamic_compression_before_cache(@url_compression.dynamic_compression_before_cache_enabled?)
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
    [:static_compression, "Dynamic compression is enabled for URLs"],
    [:dynamic_compression, "Static compression is enabled for URLs"],
    [:dynamic_compression_before_cache, "Response is dynamically compressed before it is put into the output cache"]
  ].each do |(property, name)|
    if resource_needs_change_for?(property)
      current_value = current_resource.send(property)
      desired_value = new_resource.send(property)

      converge_by("#{name} is set to #{desired_value}\n") do
        @url_compression.send("#{property}=", desired_value)
        Chef::Log.info "#{name} was set to #{desired_value} (older value was #{current_value})"
        modified = true
      end
    end

    new_resource.updated_by_last_action(modified)
  end
end
