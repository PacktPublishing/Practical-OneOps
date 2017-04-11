#
# Cookbook Name:: nodejs
# Recipe:: restart
#
service "nodejs" do
  service_name "nodejs"
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end

