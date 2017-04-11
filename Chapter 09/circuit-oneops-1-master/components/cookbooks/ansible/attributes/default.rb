default['python']['install_method'] = 'package'

if python['install_method'] == 'package'
  case platform
  when "smartos"
    default['python']['prefix_dir']         = '/opt/local'
  else
    default['python']['prefix_dir']         = '/usr'
  end
else
  default['python']['prefix_dir']         = '/usr/local'
end

if platform_family?("rhel", "fedora")
  default['python']['pip_binary'] = "/usr/bin/pip"
elsif platform_family?("smartos")
  default['python']['pip_binary'] = "/opt/local/bin/pip"
else
  default['python']['pip_binary'] = "/usr/local/bin/pip"
end

default['python']['binary'] = "#{node['python']['prefix_dir']}/bin/python"
default['python']['pip_location'] = "#{node['python']['prefix_dir']}/bin/pip"
default['python']['virtualenv_location'] = "#{node['python']['prefix_dir']}/bin/virtualenv"
default['python']['setuptools_version'] = nil # defaults to latest
default['python']['virtualenv_version'] = nil

