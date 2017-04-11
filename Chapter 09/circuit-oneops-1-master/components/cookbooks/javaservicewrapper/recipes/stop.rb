include_recipe 'javaservicewrapper::wire_ci_attr'
service node["javaservicewrapper"]["app_title"] do
                supports :status => false, :start => true, :stop => true, :restart => true
                action [ :stop ]
end
