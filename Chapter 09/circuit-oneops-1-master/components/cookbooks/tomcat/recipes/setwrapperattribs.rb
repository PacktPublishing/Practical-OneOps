node.set['javaservicewrapper']['main_class'] = 'org.apache.catalina.startup.Bootstrap'
node.set['javaservicewrapper']['working_dir'] = node['tomcat']['base'] + "/bin"
node.set['javaservicewrapper']['start_main_args'] = ['start']
node.set['javaservicewrapper']['environment_vars'] = JSON.parse(node['tomcat']['environment'])

# create array for java_params
java_params = Array.new 
if node["tomcat"]["system_properties"] != nil &&
   JSON.parse(node["tomcat"]["system_properties"]).keys.size > 0
	JSON.parse(node["tomcat"]["system_properties"]).each do |key, value|
		java_params.push("-D"+key + "=" +value)	
	end
end

if (node["tomcat"]["java_options"] != nil &&
   ! node["tomcat"]["java_options"].empty?)
                java_params.push(node["tomcat"]["java_options"])
end

if (!node["tomcat"]["mem_max"].nil?)
	java_params.push('-Xmx' + node["tomcat"]["mem_max"])
end

if (!node["tomcat"]["mem_start"].nil?)
        java_params.push('-Xms' + node["tomcat"]["mem_start"])
end

java_classpath_params = Array.new
java_classpath_params.push(node['tomcat']['base'] + "/bin/bootstrap.jar");
java_classpath_params.push(node['tomcat']['base'] + "/bin/tomcat-juli.jar");

node.set['javaservicewrapper']['java_params'] = java_params
node.set['javaservicewrapper']['java_classpath_params'] = java_classpath_params 
