# spark_thriftserver - Set up the Spark thrift server
#
# This recipe configures and installs the Spark thrift server.

require 'nokogiri'

require File.expand_path("../spark_helper.rb", __FILE__)

sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

# Spark directories
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"
spark_tmp_dir = configNode['spark_tmp_dir']

if is_client_only && configNode.has_key?('enable_thriftserver') && (configNode['enable_thriftserver'] == 'true')
  # For the Spark Thrift Server to work in SSL mode, it needs to have a
  # keystore configured.  Create the keystore and generate the passwords
  # needed.

  # Generate a keystore for the Thrift Server to use
  o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
  private_pass = (0...50).map { o[rand(o.length)] }.join
  public_pass = (0...50).map { o[rand(o.length)] }.join

  # Make sure the keystore directory exists
  directory "#{spark_dir}/conf/keystore" do
      owner "spark"
      group "spark"
      mode '0755'
      action :create
  end

  # Create the keystore
  bash "create keystore" do
      user "spark"
      cwd "#{spark_dir}/conf/keystore"
      code <<-EOF
        /usr/bin/keytool -genkeypair -alias #{node.hostname} -keystore #{node.workorder.rfcCi.ciName}.keystore -keyalg "RSA" -keysize 4096 -dname "CN=$(hostname -f),O=Hadoop" -storepass #{private_pass} -keypass #{private_pass} -validity 365
        /usr/bin/keytool -exportcert -keystore #{node.workorder.rfcCi.ciName}.keystore -alias #{node.hostname} -storepass #{private_pass} -file #{node.hostname}.cer
        /usr/bin/keytool -importcert -keystore #{node.workorder.rfcCi.ciName}.truststore -alias #{node.hostname} -storepass #{public_pass} -file #{node.hostname}.cer -noprompt
        /bin/openssl x509 -inform DER -outform PEM -in #{node.hostname}.cer -out #{node.hostname}.pem
      EOF
      not_if "/bin/ls #{spark_dir}/conf/keystore/#{node.workorder.rfcCi.ciName}.keystore"
  end

  # Create the password file that has the public truststore password
  file "#{spark_dir}/conf/keystore/pub_truststore_pass" do
      content "#{public_pass}"
      owner "spark"
      group "spark"
      mode '0644'
      action :create_if_missing
  end

  link "#{spark_dir}/conf/hive-site.xml" do
    action :delete
  end

  # The hive-site.xml file now needs to be rewritten with the Spark Thrift Server
  # values inserted.  This will allow Spark to have settings that are independent
  # of a HiveServer2 instance.
  ruby_block "rewrite_hive_site_xml" do
    block do
      origHiveSite = File.read("/opt/hive/conf/hive-site.xml")
      hiveSiteXML = Nokogiri::XML(origHiveSite)

      # hive.server2.use.SSL must be set to true
      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.use.SSL']]/value").each do |xmlNode|
        xmlNode.content = "true"
      end

      # hive.server2.keystore.path should use a keystore that is unique to Spark
      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.keystore.path']]/value").each do |xmlNode|
        xmlNode.content = "#{spark_dir}/conf/keystore/#{node.workorder.rfcCi.ciName}.keystore"
      end

      # hive.server2.keystore.password should be a password that is unique to Spark
      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.keystore.password']]/value").each do |xmlNode|
        xmlNode.content = "#{private_pass}"
      end

      # Set the parametrized AD auth options
      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.thrift.port']]/value").each do |xmlNode|
        xmlNode.content = "#{configNode['thrift_server_port']}"
      end

      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.authentication.ldap.url']]/value").each do |xmlNode|
        xmlNode.content = "ldap://#{configNode['thrift_ldap_server']}"
      end

      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.authentication.ldap.Domain']]/value").each do |xmlNode|
        xmlNode.content = "#{configNode['thrift_ldap_domain']}"
      end

      # After the values are changed, write out the file.
      File.open("#{spark_dir}/conf/hive-site.xml", "w") do |newFile|
        newFile.write hiveSiteXML.to_xml
      end
    end
  end

  # Create the service template for the thrift server.
  template "#{spark_dir}/service/spark-thriftserver" do
    source "initd-thriftserver.erb"
    owner  "root"
    group  "root"
    mode   0755
    variables ({
      :spark_dir => spark_dir,
      :spark_tmp_dir => spark_tmp_dir,
      :thriftserver_port => 10001
    })
  end

  link "/etc/init.d/spark-thriftserver" do
    to "#{spark_dir}/service/spark-thriftserver"
  end

  # For SYSTEMD setup: Under the default systemd settings, the
  # thrift server daemon process is not detected.  Create a
  # config directory for the service and drop in a config
  # file that specifies where to find the PID file and configures
  # the service to exit if this process quits.

  # Creat the config directory.
  directory "/etc/systemd/system/spark-thriftserver.service.d" do
    owner 'root'
    group 'root'
    mode  '0755'
    action :create
  end

  # Create the drop in config file.
  file "/etc/systemd/system/spark-thriftserver.service.d/custom.conf" do
    content <<-EOF
[Service]
PIDFile=/tmp/spark-spark-org.apache.spark.sql.hive.thriftserver.HiveThriftServer2-1.pid
RemainAfterExit=No
EOF
    mode    '0755'
    owner   'root'
    group   'root'
  end

else
  # The Spark Thrift Server is not configured.  Make sure it is not
  # enabled.
  # Start the Spark Thrift Server service
  service  "spark-thriftserver" do
    action [ :stop, :disable ]
  end

  # Clean up the plugin directory
  directory "/etc/systemd/system/spark-thriftserver.service.d" do
    action    :delete
    recursive true
  end

  # Remove the link to the service script
  link "/etc/init.d/spark-thriftserver" do
    action :delete
  end

  # Remove the service script
  file "#{spark_dir}/service/spark-thriftserver" do
    action :delete
  end

  # Remove the hiveserver2-site.xml file
  file "#{spark_dir}/conf/hiveserver2-site.xml" do
    action :delete
  end

  # Remove the keystore
  directory "#{spark_dir}/conf/keystore" do
    action    :delete
    recursive true
  end
end
