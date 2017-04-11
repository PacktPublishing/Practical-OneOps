%w(python-devel openssl-devel git).each do |p|
	package p do
		action :install
	end
end

if node.workorder.rfcCi.ciAttributes.pip_config == "true"
  ruby_block "create pip directory" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      out = shell_out("mkdir -p ~/.pip")
      conf = shell_out("echo \"#{node.workorder.rfcCi.ciAttributes.pip_config_content}\" > ~/.pip/pip.conf")
    end
  end
end

cookbook_file "#{Chef::Config[:file_cache_path]}/get-pip.py" do
  source 'get-pip.py'
  mode "0644"
  not_if { ::File.exists?(node.python.pip_binary) }
end

execute "install-pip" do
  cwd Chef::Config[:file_cache_path]
  command <<-EOF
  #{node['python']['binary']} get-pip.py
  EOF
  not_if { ::File.exists?(node.python.pip_binary) }
end

version = node.workorder.rfcCi.ciAttributes.ansible_version

ansible_pip "ansible" do
	version version
	action :install
end

# create ansible roles directory
directory "/etc/ansible/roles" do
	recursive true
	action :create
end

template "/etc/ansible/hosts" do
	source "hosts.erb"
end

puts "***RESULT:ansible_version=#{version}"