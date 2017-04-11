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
  @request_filtering = OO::IIS.new.request_filtering
  @current_resource = new_resource.class.new(new_resource.name)

  if iis_available?
    @current_resource.allow_double_escaping(@request_filtering.allow_double_escaping?)
    @current_resource.allow_high_bit_characters(@request_filtering.allow_high_bit_characters?)
    @current_resource.verbs(@request_filtering.verbs)
    @current_resource.max_allowed_content_length(@request_filtering.max_allowed_content_length_value)
    @current_resource.max_url(@request_filtering.max_url_value)
    @current_resource.max_query_string(@request_filtering.max_query_string_value)
    @current_resource.file_extension_allow_unlisted(@request_filtering.file_extension_allow_unlisted?)
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
    [:allow_double_escaping, "Allow non-ASCII characters in URLs"],
    [:allow_high_bit_characters, "Suppress the IIS server header"],
    [:verbs, "Allowed or denied to limit types of requests sent to the Web server"],
    [:max_allowed_content_length, "The maximum length of content in a request, in bytes"],
    [:max_url, "The maximum length of the query string, in bytes"],
    [:max_query_string, "The maximum length of the URL, in bytes"],
    [:file_extension_allow_unlisted, "The Web server should process files that have unlisted file name extensions"]
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
