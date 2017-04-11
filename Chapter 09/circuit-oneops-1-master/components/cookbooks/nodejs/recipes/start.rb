#
# Cookbook Name:: tomcat
# Recipe:: start
#
#
service "nodejs" do
  service_name "nodejs"
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
end

