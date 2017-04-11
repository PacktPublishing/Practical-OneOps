cache_dir = Chef::Config[:file_cache_path]
include_recipe "flamegraph::_#{node["flamegraph"]["cmake"]["install_method"]}"


template "#{cache_dir}/perf-map/perf_map_agent_env" do
	source 'perf_map_agent_env.erb'
	owner 'root'
	group 'root'
	mode '0755'
end


execute "Creating Perf Map Table" do
	cwd '/tmp'
	user 'root'
	action :run
	environment ({'HOME' => '/app', 'USER' => "#{node['flamegraph']['app_user']}"})
	command "sudo -u  #{node['flamegraph']['app_user']}  bash -c \"export JAVA_HOME=/usr/java/default &&   #{cache_dir}/perf-map/bin/create-java-perf-map.sh `pidof java`\""
	notifies :run, "execute[Creating Graphs]", :delayed
end

execute "Creating Graphs" do
	user 'root'
	cwd '/tmp'
	ignore_failure true
	action :run
	environment ({'HOME' => '/app', 'USER' => "#{node['flamegraph']['app_user']}"})
	command "sudo -u #{node['flamegraph']['app_user']}  bash -c \"export JAVA_HOME=/usr/java/default &&  source #{cache_dir}/perf-map/perf_map_agent_env && #{cache_dir}/perf-map/bin/perf-java-flames `pidof java` ' -a -g'\""
	action :nothing
	notifies :run, "execute[Move Flame Graph SVGs]", :delayed
end

execute "Move Flame Graph SVGs" do
	user 'root'
	command 'mv /tmp/*.svg /usr/share/nginx/html/'
	action :nothing
end
