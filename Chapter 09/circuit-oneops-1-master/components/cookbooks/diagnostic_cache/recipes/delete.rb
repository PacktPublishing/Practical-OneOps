Chef::Log.info("diagnostic-cache delete called. This is part of disabling the environment")

install_root_dir = node['diagnostic-cache']['install_root_dir']
install_app_dir = node['diagnostic-cache']['install_app_dir']
install_target_dir = "#{install_root_dir}#{install_app_dir}"

cron "cache-diagnostic-tool" do
  user 'root'
  minute "*/1"
  command "#{install_target_dir}/diagnostic-cache.rb"
  action :delete
end


cron "graphite-metrics-tool" do
  user 'root'
  minute "*/1"
  command "#{install_target_dir}/graphite-metrics-tool.rb"
  action :delete
end
