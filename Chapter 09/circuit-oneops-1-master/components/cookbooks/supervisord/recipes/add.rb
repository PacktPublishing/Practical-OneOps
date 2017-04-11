
# Create supervisord.d config directory if missing

directory "/etc/supervisord.d" do
  action :create
  owner "root"
  group "root"
end

::Chef::Recipe.send(:include, SupervisordHelper)
# Make sure Python setuptools is install
package_name = get_setuptools()

package package_name do
	action :install
end

# Install Supervisord
install()

# Perform same action as update
include_recipe "supervisord::update"

# Probe system to determine if
# system is systemd or initd
set_system_startup()

# Configure startup file to start as service
case node.system_startup
when 'systemd'
	template '/usr/lib/systemd/system/supervisord.service' do
		source "supervisord_systemd.erb"
	end
when 'initd'
	template '/etc/init.d/supervisord' do
		source "supervisord_initd.erb"
	end
end

service 'supervisord' do
	supports :status => true, :restart => true, :reload => true
	action [ :enable, :start ]
end
