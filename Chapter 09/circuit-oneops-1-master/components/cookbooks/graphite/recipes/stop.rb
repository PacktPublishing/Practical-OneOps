service "graphite" do
  service_name 'graphite'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
