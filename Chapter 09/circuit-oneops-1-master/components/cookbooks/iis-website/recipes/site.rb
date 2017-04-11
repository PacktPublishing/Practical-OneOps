site = node['iis-website']
platform_name = node.workorder.box.ciName
site_id = node.workorder.box.ciId

runtime_version = site.runtime_version
identity_type = site.identity_type

binding_type = site.binding_type
binding_port = site.binding_port
physical_path = site.physical_path

site_bindings = [{ 'protocol' => binding_type,
                   'binding_information' => "*:#{binding_port}:" }]

website_physical_path = ::File.join(physical_path, platform_name)

certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }
ssl_certificate_exists = false
thumbprint = ''

certs.each do |cert|
  if !cert[:ciAttributes][:pfx_enable].nil? && cert[:ciAttributes][:pfx_enable] == 'true'
    ssl_data = cert[:ciAttributes][:ssl_data]
    ssl_password = cert[:ciAttributes][:ssl_password]
    ssl_certificate_exists = true

    cert = OpenSSL::X509::Certificate.new(ssl_data)
    thumbprint = OpenSSL::Digest::SHA1.new(cert.to_der).to_s

    iis_certificate platform_name do
      raw_data ssl_data
      password ssl_password
    end

  end
end

directory physical_path do
  recursive true
end

iis_app_pool platform_name do
  managed_runtime_version runtime_version
  process_model_identity_type identity_type
  recycling_log_event_on_recycle ["Time", "Requests", "Schedule", "Memory", "IsapiUnhealthy", "OnDemand", "ConfigChange", "PrivateMemory"]
  process_model_user_name site.process_model_user_name if identity_type == 'SpecificUser'
  process_model_password site.process_model_password if identity_type == 'SpecificUser'
  action [:create, :update]
end

iis_web_site platform_name do
  id site_id
  bindings site_bindings
  virtual_directory_physical_path website_physical_path.tr('/', '\\')
  application_pool platform_name
  certificate_hash thumbprint if ssl_certificate_exists
  action [:create, :update]
end

iis_windows_authentication 'enabling windows authentication' do
  site_name platform_name
  enabled site.windows_authentication.to_bool
end

iis_anonymous_authentication 'anonymous authentication' do
  site_name platform_name
  enabled site.anonymous_authentication.to_bool
end

static_mime_types = JSON.parse(site.static_mime_types)

static_mime_types.each do | file_extension, mime_type |
  iis_mime_mapping 'adding mime type' do
    site_name platform_name
    file_extension file_extension
    mime_type mime_type
  end
end

include_recipe 'iis::disable_ssl'
include_recipe 'iis::enable_tls'

iis_log_location 'setting log location' do
  central_w3c_log_file_directory site.log_file_directory
  central_binary_log_file_directory site.log_file_directory
end

iis_urlcompression 'configure url compression and parameters' do
  static_compression site.enable_static_compression.to_bool
  dynamic_compression site.enable_dynamic_compression.to_bool
  dynamic_compression_before_cache site.url_compression_dc_before_cache.to_bool
end


iis_compression 'configure compression parameters' do
  max_disk_usage site.compression_max_disk_usage.to_i
  min_file_size_to_compress site.compresion_min_file_size.to_i
  directory site.sc_file_directory
  only_if { site.enable_static_compression.to_bool }
end

iis_staticcompression 'configure static compression paramters' do
  level site.sc_level.to_i
  mime_types site.sc_mime_types.to_h
  cpu_usage_to_disable site.sc_cpu_usage_to_disable.to_i
  cpu_usage_to_reenable site.sc_cpu_usage_to_reenable.to_i
  directory site.sc_file_directory
  only_if { site.enable_static_compression.to_bool }
end

iis_dynamiccompression 'configure dynamic compression paramters' do
  level site.dc_level.to_i
  mime_types site.dc_mime_types.to_h
  cpu_usage_to_disable site.dc_cpu_usage_to_disable.to_i
  cpu_usage_to_reenable site.dc_cpu_usage_to_reenable.to_i
  directory site.dc_file_directory
  only_if { site.enable_dynamic_compression.to_bool }
end

iis_requestfiltering 'configure request filter parameters' do
  allow_double_escaping site.requestfiltering_allow_double_escaping.to_bool
  allow_high_bit_characters site.requestfiltering_allow_high_bit_characters.to_bool
  verbs site.requestfiltering_verbs.to_h
  max_allowed_content_length site.requestfiltering_max_allowed_content_length.to_i
  max_url site.requestfiltering_max_url.to_i
  max_query_string site.requestfiltering_max_query_string.to_i
  file_extension_allow_unlisted site.requestfiltering_file_extension_allow_unlisted.to_bool
end

iis_isapicgirestriction 'configure isapi cgi restriction' do
  not_listed_isapis_allowed false
  not_listed_cgis_allowed false
end

iis_sessionstate 'configure session state parameters' do
  site_name platform_name
  cookieless site.session_state_cookieless
  cookiename site.session_state_cookie_name
  time_out site.session_time_out.to_i
end
