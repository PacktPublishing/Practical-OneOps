include_recipe 'javaservicewrapper::wire_ci_attr'

service node["javaservicewrapper"]["app_title"] do
                supports :status => true, :start => true, :stop => true, :restart => true
                action [ :restart ]
end
