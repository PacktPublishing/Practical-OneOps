def whyrun_supported?
  true
end

def load_current_resource
  @mime_mapping = OO::IIS.new.mime_mapping(new_resource.site_name)
  @current_mime_types = @mime_mapping.mime_types
  @web_site = OO::IIS.new.web_site(new_resource.site_name)
  @new_mime_type = {'file_extension' => "#{new_resource.file_extension}", 'mime_type' => "#{new_resource.mime_type}"}
end

def resource_needs_change?
  !(Array.new([@new_mime_type]) - @current_mime_types).empty?
end
private :resource_needs_change?

def iis_available?
  OO::IIS::Detection.aspnet_enabled? and OO::IIS::Detection.major_version >= 7
end
private :iis_available?

def define_resource_requirements
  requirements.assert(:configure) do |a|
    a.assertion { iis_available?  }
    a.failure_message("IIS 7 or a later version needs to be installed / enabled")
    a.whyrun("Would enable IIS 7")
  end
end

action :add do
  updated = false
  if @web_site.exists?
    if resource_needs_change?
      converge_by("add mime types for website #{new_resource.site_name}") do
        puts @new_mime_type
        @mime_mapping.add_mime_type(@new_mime_type)
        updated = true
      end
    end
  end
  new_resource.updated_by_last_action(updated)
end
