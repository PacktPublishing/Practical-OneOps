#
# Cookbook Name:: tomcat
# Recipe:: stop
#
service "nodejs" do
  service_name "nodejs"
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end


