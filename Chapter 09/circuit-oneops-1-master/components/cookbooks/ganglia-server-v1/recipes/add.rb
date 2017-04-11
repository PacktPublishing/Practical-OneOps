# Add - Add the Ganglia Server components
#
# This recipe installs all of the components that are required for
# a Ganglia Server.

Chef::Log.info("Running #{node['app_name']}::add")

configName = node['app_name']
configNode = node[configName]

gweb_port = configNode['gweb_port']

cache_path = Chef::Config[:file_cache_path]

include_recipe "#{configName}::prerequisites"

# Install the packages
package 'ganglia-gmond'
package 'ganglia-gmetad'
package 'ganglia-web'

# Create a directory for all of the server config files
directory "/etc/ganglia/serverconf.d" do
  owner  "root"
  group  "root"
  mode   "0755"
  action :create
end

# Create a separate gmond-server that is used for remote data sources
execute "copy_gmond" do
  command 'cp -p /usr/sbin/gmond /usr/sbin/gmond-server'
  creates '/usr/sbin/gmond-server'
end

# Update the Apache config to use the right port
bash "update_listen_port" do
  code <<-EOH
    cat /etc/httpd/conf/httpd.conf |sed "/^Listen /c\Listen #{gweb_port}" > #{cache_path}/httpd.conf.tmp
    mv #{cache_path}/httpd.conf.tmp /etc/httpd/conf/httpd.conf
  EOH
end

# Enable the /ganglia context in Apache
template "/etc/httpd/conf.d/ganglia.conf" do
    source "ganglia.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables ({
      :gweb_port => configNode['gweb_port']
    })
end

cookbook_file "/etc/httpd/conf.d/welcome.conf" do
    source "welcome.conf"
    owner "root"
    group "root"
    mode "0644"
end

# default config for ganglia gmond
cookbook_file "/etc/ganglia/gmond.conf" do
    source "gmond.conf"
    owner "root"
    group "root"
    mode "0644"
end

# Generate the gmetad configuration file
template "/etc/ganglia/gmetad.conf" do
  source "gmetad.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables ({
    :data_source_map => configNode['data_source_map'],
    :polling_interval => configNode['polling_interval'],
    :grid_name => configNode['grid_name']
  })
end

# Create the Jobs report
cookbook_file "/usr/share/ganglia/graph.d/cluster_jobs_report.php" do
  source "cluster_jobs_report.php"
  owner  "root"
  group  "root"
  mode   "0644"
end

# Add a server gmond for each service
sourceMapString = configNode['data_source_map']
sourceMap = JSON.parse(sourceMapString)

sourceMap.each_key { |sourcePort|
  sourceName = sourceMap[sourcePort]

  template "/etc/ganglia/serverconf.d/gmond-#{sourcePort}.conf" do
      source "server-gmond.conf.erb"
      owner "root"
      group "root"
      mode "0644"
      variables ({
        :cluster_name => sourceName,
        :source_port => sourcePort
      })
  end

  # Create a view file for this data source
  view_name = sourceName.gsub(' ', '_')

  template "/var/lib/ganglia/conf/view_#{view_name}.json" do
      source "data_source_view.json.erb"
      owner "root"
      group "root"
      mode "0644"
      variables ({
        :cluster_name => sourceName,
        :source_port => sourcePort,
        :view_name => view_name
      })
  end

  # Create a cluster view for this data source
  file "/var/lib/ganglia/conf/cluster_#{view_name}.json" do
    content <<-EOF
{
  "included_reports": [
    "cluster_jobs_report",
    "load_report"
  ]
}
EOF
    owner "apache"
    group "apache"
    mode  "0644"
  end
}

# Create the server gmond service script
template "/etc/init.d/gmond-server" do
  source "initd-gmond-server.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({

  })
end

# Remember the current action name
if node.workorder.has_key?("rfcCi")
  actionName = node.workorder.rfcCi.rfcAction
else
  actionName = node.workorder.actionName
end

# Start or restart the services as necessary.
if actionName == 'update'
  service 'gmond-server' do
    action :restart
  end

  service 'gmetad' do
    action :restart
  end

  service 'httpd' do
    action :restart
  end
else
  # There is no generic gmond.
  service 'gmond' do
    action :disable
  end

  service 'gmond-server' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end

  service 'gmetad' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end

  service 'httpd' do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
end
