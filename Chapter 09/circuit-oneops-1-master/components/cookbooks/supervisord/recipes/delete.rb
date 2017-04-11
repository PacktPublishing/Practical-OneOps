# Un-install Supervisord
::Chef::Recipe.send(:include, SupervisordHelper)

# Stop service 
service 'supervisord' do
	action [ :stop ]
end

# Uninstall supervisord
uninstall