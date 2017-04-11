
case node[:platform]
when "debian", "ubuntu"
  rabbitmq_repository "rabbitmq" do
    uri "http://www.rabbitmq.com/debian/"
    distribution "testing"
    components ["main"]
    key "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
    action :add
  end
  package "rabbitmq-server" do
    action :install
    options "--force-yes"
  end
when "redhat", "centos", "fedora"
  package "erlang"
  package "socat"
end

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key? "mirror"
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
else
  mirrors = Hash.new
end

source = mirrors["rabbitmq-server"]
if source.nil?
  Chef::Log.info("rabbitmq source repository has not beed defined in cloud mirror service.. taking default #{node.rabbitmq_server.source}")
  source = node.rabbitmq_server.source
else
  Chef::Log.info("using rabbitmq source repository that has been defined in cloud mirror service #{source}")
end

version = node.rabbitmq_server.version

if node.platform_version.start_with?("6")
  file_name = "rabbitmq-server-#{version}-1.el6.noarch.rpm"
elsif node.platform_version.start_with?("7")
  file_name = "rabbitmq-server-#{version}-1.el7.noarch.rpm"
end

shared_download_http "#{source}/v#{version}/#{file_name}" do
  path "/tmp/#{file_name}"
  action :create
end

bash "Install Rabbitmq" do
  code <<-EOH
  rpm -ivh /tmp/#{file_name}
  chkconfig rabbitmq-server on
  EOH
end

service "rabbitmq-server" do
  action :stop
end

directory node.rabbitmq_server.config_path do
  owner "root"
  group "root"
  mode 0755
  action :create
end

template "#{node.rabbitmq_server.config_path}/rabbitmq-env.conf" do
  source "rabbitmq-env.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables({
    :environment_variables => JSON.parse(node.rabbitmq_server.environment_variables)
    })
end

template "#{node.rabbitmq_server.config_path}/rabbitmq.config" do
  source "rabbitmq.config.erb"
  owner "root"
  group "root"
  mode 0644
  variables({
    :config_variables => JSON.parse(node.rabbitmq_server.config_variables).map { |k, v| "{#{k}, #{v}}" }.join(",")
    })
  not_if { JSON.parse(node.rabbitmq_server.config_variables).empty? }
end

template "/var/lib/rabbitmq/.erlang.cookie" do
  source "doterlang.cookie.erb"
  owner "rabbitmq"
  group "rabbitmq"
  mode 0400
end

execute "Remove old rabbitmq data directory" do
  command "rm -rf /var/lib/rabbitmq/mnesia"
end

data_path = JSON.parse(node.rabbitmq_server.environment_variables).has_key?("RABBITMQ_MNESIA_BASE") ? JSON.parse(node.rabbitmq_server.environment_variables)["RABBITMQ_MNESIA_BASE"] : node.rabbitmq_server.data_path
log_path = JSON.parse(node.rabbitmq_server.environment_variables).has_key?("RABBITMQ_LOG_BASE") ? JSON.parse(node.rabbitmq_server.environment_variables)["RABBITMQ_LOG_BASE"] : node.rabbitmq_server.log_path

[data_path, log_path].each do |dir|
  directory dir do
    owner "rabbitmq"
    group "rabbitmq"
    mode 0755
    action :create
    recursive true
  end
end

service "rabbitmq-server" do
  action [:enable, :start]
end

execute "Enable Rabbitmq Management" do
  not_if "/usr/lib/rabbitmq/bin/rabbitmq-plugins  list | grep '\[E\].*rabbitmq_management'"
  command "/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management"
  user 0
  action :run
end

rabbitmq_server_user node.rabbitmq_server.guest_user do
  password node.rabbitmq_server.guest_password
  action :add
end

rabbitmq_server_user node.rabbitmq_server.admin_user do
  password node.rabbitmq_server.admin_password
  action :add
end

[node.rabbitmq_server.guest_user, node.rabbitmq_server.admin_user].each do |user|
  rabbitmq_server_user user do
    permissions "\".*\" \".*\" \".*\""
    action :set_permissions
  end
  execute "/usr/sbin/rabbitmqctl set_user_tags #{user} administrator"
end

service "rabbitmq-server" do
  action :restart
end

file "/tmp/#{file_name}" do
  action :delete
end
