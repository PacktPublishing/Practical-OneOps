        app_name = node.workorder.ci.ciAttributes.app_name
        service "#{app_name}" do
		supports :status => true, :start => true, :stop => true, :restart => true
		action [ :start ]
	end
