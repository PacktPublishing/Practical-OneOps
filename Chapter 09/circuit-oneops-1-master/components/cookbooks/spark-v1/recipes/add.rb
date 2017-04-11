# Add - Add the Spark components
#
# This recipe installs all of the components that are required for
# Spark.

Chef::Log.info("Running #{node['app_name']}::add")

include_recipe "#{node['app_name']}::prerequisites"

require File.expand_path("../spark_helper.rb", __FILE__)

# Assume that this is a Spark master unless dependent configurations are found
sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
spark_master_ip = sparkInfo[:spark_master_ip]
configNode = sparkInfo[:config_node]
is_using_zookeeper = sparkInfo[:is_using_zookeeper]

use_yarn = false
if configNode['use_yarn'] == 'true'
  use_yarn = true
end

spark_cache_path = Chef::Config[:file_cache_path] + "/spark"

# The base directory for Hadoop
hadoop_dir = configNode['hadoop_dir']

# The base directory for Hive
hive_dir = configNode['hive_dir']

# The parent directory for all Spark files
spark_base = configNode['spark_base']

# The temp directory where Spark will store working files
spark_tmp_dir = configNode['spark_tmp_dir']

spark_dir = "#{spark_base}/spark"

directory spark_cache_path do
  owner 'root'
  group 'root'
  mode  '0755'
end

# Add the spark group and user
group "spark" do
  action :create
end

user "spark" do
  comment "Spark user"
  group "spark"
  action :create
end

group "ssh_keys" do
    append true
    action :modify
    members "spark"
end

# Create the Spark directory
directory "#{spark_base}" do
  owner     'spark'
  group     'spark'
  mode      '0755'
  recursive true
  action :create
end

# Create the Spark tmp directory
directory "#{spark_tmp_dir}" do
  owner     'spark'
  group     'spark'
  mode      '0777'
  recursive true
  action :create
end

# Make sure the hive /tmp directory has the correct
# permissions.  Some distributions have this set improperly,
# so just set it here.
directory "/tmp/hive" do
  owner     'hive'
  group     'hive'
  mode      '0777'
  action :create
  only_if { is_client_only }
end

# Find the location of the Spark distribution to download
dest_file = ""

# Parse the file names out of the custom tarball link provided.
spark_dist_url = configNode['spark_custom_download']

Chef::Log.debug("spark_dist_url: #{spark_dist_url}")

dest_file = spark_cache_path + '/spark-dist.tgz'

if spark_dist_url == ""
  puts "***FAULT:FATAL=The download location could not be found.  Please specify the Spark distribution to download."
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end

# Download the Spark distribution

#remote_file dest_file do
#  source spark_dist_url
#  action :create_if_missing
#end

# remote_file produces way too much output in debug environments
bash "download_spark" do
    user "root"
    code <<-EOF
        /usr/bin/curl "#{spark_dist_url}" -o "#{dest_file}"

        tar -tf "#{dest_file}" >/dev/null 2>&1
        RETCODE=$?

        if [[ "$RETCODE" != "0" ]]; then
          echo "***FAULT:FATAL=The archive #{spark_dist_url} is not a valid archive.  Cleaning up..."
          rm -rf "#{dest_file}"
        fi

        # Allow this resource to exit gracefully.  The error
        # condition will be checked and reported by the
        # check_spark_archive resource.
        #exit $RETCODE
        exit 0
    EOF
    not_if "/bin/ls #{dest_file}"
end

ruby_block "check_spark_archive" do
  block do
    if !File.file?("#{dest_file}")
      puts "***FAULT:FATAL=Unable to download Spark archive.  Please check the log for details."

      # Raise an exception
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  end
end

bash "extrack_spark" do
    user "root"
    code <<-EOF
      NEW_DIR=`tar -tf #{dest_file} |head -n 1 |sed 's|/||'`

      if [[ "$NEW_DIR" == "" ]]; then
        echo "Unable to detect Spark archive directory.  This may indicate a problem with the Spark archive file."
        exit 1
      else
        tar -xf #{dest_file} -C #{spark_base}

        chown -R spark:spark #{spark_base}/$NEW_DIR

        ln -sfn #{spark_base}/$NEW_DIR #{spark_dir}
      fi
    EOF
end

# Remember the current action name
if node.workorder.has_key?("rfcCi")
  actionName = node.workorder.rfcCi.rfcAction
else
  actionName = node.workorder.actionName
end

if use_yarn
  # Submit jobs to Yarn
  sparkMasterURL = 'yarn'
else
  # Save the Spark master URL.  This is the Spark master for single
  # master environments (that don't use Zookeeper)
  sparkMasterURL = "spark://#{spark_master_ip}:7077"
end

# Store the Spark master URL on the file system
file "#{spark_dir}/conf/spark.master" do
  content sparkMasterURL
  mode    '0644'
  owner   'spark'
  group   'spark'
  not_if  { is_using_zookeeper }
end

file "#{spark_dir}/conf/spark.master" do
  content ""
  mode    '0644'
  owner   'spark'
  group   'spark'
  only_if  { is_using_zookeeper }
end

# Create spark-env.sh from a template
template "#{spark_dir}/conf/spark-env.sh" do
  source 'spark-env.sh.erb'
  mode   '0755'
  owner  'spark'
  group  'spark'
  variables ({
    :spark_dir => spark_dir,
    :spark_tmp_dir => spark_tmp_dir,
    :hadoop_dir => hadoop_dir
  })
end

# Generate the Hadoop layout file
template "#{hadoop_dir}/libexec/hadoop-layout.sh" do
  source 'hadoop-layout.sh.erb'
  mode   '0644'
  owner  'spark'
  group  'spark'
  variables ({
    :hadoop_dir => hadoop_dir,
  })
end

# Create spark-defaults.conf from a template
template "#{spark_dir}/conf/spark-defaults.conf" do
  source 'spark-defaults.conf.erb'
  mode   '0644'
  owner  'spark'
  group  'spark'
  variables ({
    :spark_dir => spark_dir,
    :spark_events_dir => configNode['spark_events_dir'],
    :history_server_port => configNode['history_server_port']
  })
end

# Create a script to fix the paths in the spark-defaults.conf
template "#{spark_dir}/fix_spark_defaults.sh" do
  source 'fix_spark_defaults.sh.erb'
  mode   '0755'
  owner  'spark'
  group  'spark'
  variables ({
    :spark_dir => spark_dir,
    :hive_dir => hive_dir
  })
end

# Create the log4j.properties file from a template
template "#{spark_dir}/conf/log4j.properties" do
  source 'log4j.properties.erb'
  mode   '0644'
  owner  'spark'
  group  'spark'
  only_if { !is_client_only }
end

template "#{spark_dir}/conf/log4j.properties" do
  source 'log4j-client.properties.erb'
  mode   '0644'
  owner  'spark'
  group  'spark'
  only_if { is_client_only }
end

# Create a symlink to the Hive configuration if this is a client.
link "#{spark_dir}/conf/hive-site.xml" do
  to "#{hive_dir}/conf/hive-site.xml"
  only_if { is_client_only }
end

include_recipe "#{node['app_name']}::config_user_profile"

include_recipe "#{node['app_name']}::trust_pub_keys"

# Set up Ganglia
if configNode['enable_ganglia'] == 'true'
  include_recipe "#{node['app_name']}::gmond"
else
  Chef::Log.info("Ganglia not enabled")
end

# If this recipe was successful, clean up all locally generated files
# Don't clean up files in debug environments

directory spark_cache_path do
  action :delete
  recursive true
  not_if { node.workorder.payLoad.Environment[0].ciAttributes.debug == 'true' }
end

# Configure and start the Spark services

# Create the Spark log directory
directory "#{spark_tmp_dir}/logs" do
  owner 'spark'
  group 'spark'
  mode  '0755'
  action :create
end

template "/opt/nagios/libexec/check_spark_log.sh" do
  source "check_spark_log.sh.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({
    :spark_log_dir => "#{spark_tmp_dir}/logs"
  })
end

# Create the Spark service directory
directory "#{spark_dir}/service" do
  owner 'spark'
  group 'spark'
  mode  '0755'
  action :create
end

# Create the master service start/stop script only if this is the Spark master
template "#{spark_dir}/service/spark-master" do
  source "initd-master.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({
    :spark_dir => spark_dir,
    :spark_tmp_dir => spark_tmp_dir
  })
  only_if { !is_client_only }
end

# Create the worker service start/stop script only if this is NOT the Spark master
template "#{spark_dir}/service/spark-worker" do
  source "initd-worker.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({
    :spark_dir => spark_dir,
    :spark_tmp_dir => spark_tmp_dir
  })
  only_if { !is_client_only }
end

# Create a link to the correct startup script
link "/etc/init.d/spark" do
  to "#{spark_dir}/service/spark-master"
  only_if { is_spark_master && !is_client_only }
end

link "/etc/init.d/spark" do
  to "#{spark_dir}/service/spark-worker"
  only_if { !is_spark_master && !is_client_only }
end

# For SYSTEMD setup: Under the default systemd settings, the
# Spark daemon process is not detected.  Create a config directory
# for the service and drop in a config file that specifies where
# to find the PID file and configures the service to exit if this
# process quits.

# Creat the config directory.
directory "/etc/systemd/system/spark.service.d" do
  owner 'root'
  group 'root'
  mode  '0755'
  action :create
  only_if { !is_client_only }
end

configContent = ""

if is_spark_master
  configContent = <<-EOF
[Service]
PIDFile=/tmp/spark-spark-org.apache.spark.deploy.master.Master-1.pid
RemainAfterExit=No
EOF
else
  configContent = <<-EOF
[Service]
PIDFile=/tmp/spark-spark-org.apache.spark.deploy.worker.Worker-1.pid
RemainAfterExit=No
EOF
end

# Create the drop in config file.
file "/etc/systemd/system/spark.service.d/custom.conf" do
  content configContent
  mode    '0755'
  owner   'root'
  group   'root'
  only_if { !is_client_only }
end

# Configure (or disable) the Spark History server
include_recipe "#{node['app_name']}::historyserver"

# Configure (or disable) the Spark Thrift server
include_recipe "#{node['app_name']}::spark_thriftserver"

# Create the master service start/stop script only if this is the Spark master
template "/opt/nagios/libexec/worker_status.sh" do
  source "worker_status.sh.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({
    :spark_master_ip => spark_master_ip
  })
  only_if { is_spark_master }
end

# Create a template file that will read the Spark master location
# for each of the built in tools
#
deploy_mode = ""
if use_yarn
  deploy_mode = "client"
end

for sparkTool in ['spark-submit', 'spark-sql', 'spark-shell', 'sparkR', 'run-example', 'spark-class', 'pyspark'] do
  template "/usr/bin/#{sparkTool}" do
    source "spark-tool.erb"
    owner "spark"
    group "spark"
    mode 0755
    variables ({
      :spark_dir => spark_dir,
      :deploy_mode => deploy_mode
    })
    only_if { is_client_only }
  end
end

cookbook_file "/usr/bin/beeline" do
  source "beeline.sh"
  owner "root"
  group "root"
  mode "0755"
  only_if { is_client_only }
end

ruby_block "detect_spark_version" do
  block do
    detected_version = `#{spark_dir}/bin/spark-shell --version 2>&1 |grep version |sed "s/^.*version //"`

    puts "***RESULT:spark_version=#{detected_version}"
  end
end

if actionName == "replace"
  # During a replace, save all start operations for the ring
  # component. This component will know the mapping of all masters to
  # workers
else
  # Start the cluster now only if the cluster is not configured to use
  # Zookeeper.  If Zookeeper is being used, a delayed start will need
  # to be done after all Spark masters are known.
  if !is_using_zookeeper
    if actionName == "update"
      include_recipe "#{node['app_name']}::spark_restart"
    else
      include_recipe "#{node['app_name']}::spark_start"
    end
  end
end

Chef::Log.info("#{node['app_name']}::add completed, Spark master URI is: #{sparkMasterURL}")
