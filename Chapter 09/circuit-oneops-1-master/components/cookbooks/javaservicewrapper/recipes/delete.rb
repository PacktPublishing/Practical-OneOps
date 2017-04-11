include_recipe 'javaservicewrapper::wire_ci_attr'

if (File.exists?('/etc/init.d/' + node['javaservicewrapper']['app_title']))
	service node["javaservicewrapper"]["app_title"] do
	                supports :status => true, :start => true, :stop => true, :restart => true
	                action [ :stop ]
	end
end

#remove the previsouly installed daemons if any
if (File.exists?('/etc/init.d/' + node['javaservicewrapper']['app_title']))
bash 'uninstall_daemon' do
  cwd "#{node['javaservicewrapper']['install_dir']}/jsw/#{node['javaservicewrapper']['app_title']}/bin"
    code <<-EOH
        ./uninstallDaemon.sh
            EOH
      end
end



