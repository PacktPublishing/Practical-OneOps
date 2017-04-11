cache_dir = Chef::Config[:file_cache_path]
package 'git' do
	action :install
end

directory "#{cache_dir}/perf-map" do
	owner	"#{node['flamegraph']['app_user']}"
	group	"#{node['flamegraph']['app_user']}"
	mode	'0755'
	action	:create
end

git "#{cache_dir}/perf-map" do
	repository 'https://github.com/jrudolph/perf-map-agent.git'
	revision 'master'
	action  :sync
	user "#{node['flamegraph']['app_user']}"
end

include_recipe "flamegraph::build_essential"
include_recipe "flamegraph::_#{node["flamegraph"]["cmake"]["install_method"]}"

package 'Install Perf Tool' do
	case node[:platform]
	when 'redhat', 'centos'
		package_name 'perf'
	when 'ubuntu', 'debian'
		package_name "linux-tools-#{node["kernel"]["release"]}"
	end
	action :install
end

template "#{cache_dir}/perf-map/perf_map_agent_env" do
	source 'perf_map_agent_env.erb'
	owner "#{node['flamegraph']['app_user']}"
	group "#{node['flamegraph']['app_user']}"
	mode '0755'
end

directory "#{node['flamegraph']['flamegraph_dir']}" do
	action	:create
	owner   "#{node['flamegraph']['app_user']}"
	group   "#{node['flamegraph']['app_user']}"
	mode    '0755'
end

git "#{node['flamegraph']['flamegraph_dir']}" do
	repository 'https://github.com/brendangregg/FlameGraph.git'
	revision 'master'
	action  :sync
	user "#{node['flamegraph']['app_user']}"
end

cookbook_file "/etc/nginx/conf.d/default.conf" do
	source "nginx_default.conf"
	owner "root"
	group "root"
	mode "0644"
	notifies :run, "execute[Restart Nginx]", :delayed
end

file "/usr/share/nginx/html/index.html" do
	action :delete
	only_if { File.exists?("/usr/share/nginx/html/index.html") }
end

execute "Restart Nginx" do
	command "service nginx restart"
	action :nothing
end
