# Delete - Delete the Ganglia Server components
#
# This recipe removes all components used for Ganglia.

Chef::Log.info("Running #{node['app_name']}::delete")

# Stop all the services
service 'httpd' do
  action :stop
end

service 'gmetad' do
  action :stop
end

service 'gmond-server' do
  action :stop
end

directory "/etc/ganglia/serverconf.d" do
  action    :delete
  recursive true
end

# Delete the ganglia context file in Apache
file "/etc/httpd/conf.d/ganglia.conf" do
  action :delete
end

# Clean up the gmond-server file
file "/usr/sbin/gmond-server" do
  action :delete
end

# Clean up the packages
package 'ganglia-web' do
  action :delete
end

package 'ganglia-gmetad' do
  action :delete
end

package 'ganglia-gmond' do
  action :delete
end
