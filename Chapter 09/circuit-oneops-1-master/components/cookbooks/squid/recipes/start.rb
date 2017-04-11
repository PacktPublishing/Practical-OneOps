service node['squid']['service_name'] do
  supports :restart => true, :status => true, :reload => true, :stop => true, :start => true
  provider Chef::Provider::Service::Upstart if platform?('ubuntu')
  action :start
end
