#remove the previsouly installed daemons if any
if (File.exists?('/etc/init.d/' + node['javaservicewrapper']['app_title']))
bash 'uninstall_daemon' do
  cwd "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/bin"
  code <<-EOH
#        ./uninstallDaemon.sh
        EOH
end
end

directory "#{node['javaservicewrapper']['working_dir']}" do
  mode 00755
  owner node['javaservicewrapper']['as_user']
  group node['javaservicewrapper']['as_group']
  recursive true
  action :create
end

# generate the wrapper.conf
template "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/conf/wrapper.conf" do
  source "wrapper.conf.erb"
  owner "#{node['javaservicewrapper']['as_user']}"
  group "#{node['javaservicewrapper']['as_group']}"
  mode "0755"
end

if node["javaservicewrapper"]["wrapper_stop_text"] != nil && ! node["javaservicewrapper"]["wrapper_stop_text"].empty?
template "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/conf/stop.conf" do
  source "stop.conf.erb"
  owner "#{node['javaservicewrapper']['as_user']}"
  group "#{node['javaservicewrapper']['as_group']}"
  mode "0755"
end
end 

#install the daemons

bash 'install_daemon' do
  cwd "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/bin"
  code <<-EOH
        ./installDaemon.sh
        EOH
  returns [0,1]
end
