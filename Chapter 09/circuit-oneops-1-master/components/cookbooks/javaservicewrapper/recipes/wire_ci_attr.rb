if (node.has_key?("javaservicewrapper"))
	  ci = node.javaservicewrapper
end

Chef::Log.info "JSW Config : #{node.javaservicewrapper}"

node.set[:javaservicewrapper][:main_class] = ci['main_class']
if !ci['start_main_args'].nil? && !ci['start_main_args'].empty?
	node.set[:javaservicewrapper][:start_main_args] = JSON.parse(ci['start_main_args'])
end

node.set[:javaservicewrapper][:jmx] = ci['jmx']
node.set[:javaservicewrapper][:install_dir] = ci['install_dir']
node.set[:javaservicewrapper][:as_group] = ci['as_group']
node.set[:javaservicewrapper][:working_dir] = ci['working_dir']

if !ci['java_classpath_params'].nil? && !ci['java_classpath_params'].empty?
	node.set[:javaservicewrapper][:java_classpath_params] = JSON.parse(ci['java_classpath_params'])
end

node.set[:javaservicewrapper][:wrapper_stop_text] = ci['wrapper_stop_text']
node.set[:javaservicewrapper][:as_user] = ci['as_user']
node.set[:javaservicewrapper][:url] = ci['url']
node.set[:javaservicewrapper][:additional_wrapper_text] = ci['additional_wrapper_text']

if !ci['java_params'].nil? && !ci['java_params'].empty?
	node.set[:javaservicewrapper][:java_params] = JSON.parse(ci['java_params'])
end

node.set[:javaservicewrapper][:app_title] = ci['app_title']

if !ci['environment_vars'].nil? && !ci['environment_vars'].empty?
	node.set[:javaservicewrapper][:environment_vars] = JSON.parse(ci['environment_vars'])
end
