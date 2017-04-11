# historyserver - Set up the Spark history server
#
# This recipe configures and installs the Spark history server.

require File.expand_path("../spark_helper.rb", __FILE__)

sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]
enable_historyserver = configNode.has_key?('enable_historyserver') && configNode['enable_historyserver'] == 'true'

# Spark directories
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"
spark_tmp_dir = configNode['spark_tmp_dir']
spark_events_dir = configNode['spark_events_dir']

if is_client_only && enable_historyserver
  # Create the Spark events directory
  directory "#{spark_events_dir}" do
    owner     'spark'
    group     'spark'
    # Mode set to 3777 to turn on the setgid bit and make world writable
    mode      '3777'
    recursive true
    action :create
  end

  # Create the service template for the history server.
  template "#{spark_dir}/service/spark-historyserver" do
    source "initd-historyserver.erb"
    owner  "root"
    group  "root"
    mode   0755
    variables ({
      :spark_dir => spark_dir,
      :spark_tmp_dir => spark_tmp_dir
    })
  end

  link "/etc/init.d/spark-historyserver" do
    to "#{spark_dir}/service/spark-historyserver"
  end

  # For SYSTEMD setup: Under the default systemd settings, the
  # history server daemon process is not detected.  Create a
  # config directory for the service and drop in a config
  # file that specifies where to find the PID file and configures
  # the service to exit if this process quits.

  # Create the config directory.
  directory "/etc/systemd/system/spark-historyserver.service.d" do
    owner 'root'
    group 'root'
    mode  '0755'
    action :create
  end

  # Create the drop in config file.
  file "/etc/systemd/system/spark-historyserver.service.d/custom.conf" do
    content <<-EOF
[Service]
PIDFile=/tmp/spark-spark-org.apache.spark.deploy.history.HistoryServer-1.pid
RemainAfterExit=No
EOF
    mode    '0755'
    owner   'root'
    group   'root'
  end

else
  # The Spark History Server is not configured.  Make sure it is not
  # enabled.
  # Stop and disable the Spark History Server service
  service  "spark-historyserver" do
    action [ :stop, :disable ]
  end

  # Clean up the plugin directory
  directory "/etc/systemd/system/spark-historyserver.service.d" do
    action    :delete
    recursive true
  end

  # Remove the link to the service script
  link "/etc/init.d/spark-historyserver" do
    action :delete
  end

  # Remove the service script
  file "#{spark_dir}/service/spark-historyserver" do
    action :delete
  end
end
