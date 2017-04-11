_name = node.workorder.rfcCi.ciName
_source = (node.workorder.rfcCi.ciAttributes.source).strip
#_action = node.workorder.rfcCi.ciAttributes.action or 'get'
#_message = node.workorder.rfcCi.ciAttributes.message or nil
_user = ''
_password = ''
if node.workorder.rfcCi.ciAttributes.has_key?("basic_auth_user")
  _user = node.workorder.rfcCi.ciAttributes.basic_auth_user
end
if node.workorder.rfcCi.ciAttributes.has_key?("basic_auth_password")
  _password = node.workorder.rfcCi.ciAttributes.basic_auth_password
end
_headers = node.workorder.rfcCi.ciAttributes.headers or '{}'
_post_download_exec_cmd = nil
if node.workorder.rfcCi.ciAttributes.has_key?("post_download_exec_cmd")
  _post_download_exec_cmd = node.workorder.rfcCi.ciAttributes.post_download_exec_cmd
end

_headers = _headers.empty? ? Hash.new : JSON.parse(_headers)
_path = node.workorder.rfcCi.ciAttributes.path or '/tmp/download_file'
_checksum = ''
if node.workorder.rfcCi.ciAttributes.has_key?("checksum")
  _checksum = node.workorder.rfcCi.ciAttributes.checksum
end

_d = File.dirname(_path)


directory "#{_d}" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
  not_if "test -d #{_d}"
end

# Sets tmp dir as the file dir
ruby_block 'set_tmp_dir' do
  begin
    tmp_dir = ::File.dirname(_path)
    Chef::Log.info("Setting TMPDIR env to #{tmp_dir}")
    ENV['TMPDIR'] = tmp_dir
  end
  action :nothing
end

shared_download_http "#{_source}" do
  path _path
  checksum _checksum
  headers(_headers) if _headers
  basic_auth_user _user.empty? ? nil : _user
  basic_auth_password _password.empty? ? nil : _password
  # action :nothing
  action :create
  not_if do _source =~ /s3:\/\// end
end


shared_s3_file "#{_source}" do
  source _source
  path _path
  access_key_id _user
  secret_access_key _password
  owner "root"
  group "root"
  mode 0644
  action :create  
  only_if do _source =~ /s3:\/\// end
end

# check file
execute "ls -l #{_path}"

execute "#{_post_download_exec_cmd}" if ( _post_download_exec_cmd && !_post_download_exec_cmd.empty? )
