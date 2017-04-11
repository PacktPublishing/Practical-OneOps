#
# Cookbook Name:: nginx
# Recipe:: restart

service "nginx" do
  action :restart
end
