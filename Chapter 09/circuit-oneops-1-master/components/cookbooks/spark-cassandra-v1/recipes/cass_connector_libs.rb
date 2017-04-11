# cass_connector_libs - Add the Spark Cassandra connector libraries
#
# This recipe installs all of the libraries that are needed for the
# Spark Cassandra connector.

Chef::Log.info("Running #{node['app_name']}::cass_connector_libs")

require File.expand_path("../spark_cassandra_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

# Determine the Spark version
spark_cache_path = Chef::Config[:file_cache_path] + "/spark_cassandra"

# Spark directories
spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

connector_dir = spark_dir + "/connector"

spark_version = configNode['spark_version']

nexus_url = find_nexus_url()

directory spark_cache_path do
  owner 'root'
  group 'root'
  mode  '0755'
end

# Make sure the connector directory is present
directory connector_dir do
  owner   'spark'
  group   'spark'
  mode    '0755'
  action  :create
end

if spark_version == "custom"
  # In a custom installation, use the connector library tarball
  # to download the libraries
  connector_url = configNode['connector_tarball']
  dest_file = spark_cache_path + '/spark-connector-dist.tgz'

  bash "download_connector" do
      user "root"
      code <<-EOF
          /usr/bin/curl "#{connector_url}" -o "#{dest_file}"

          tar -tf "#{dest_file}" >/dev/null 2>&1
          RETCODE=$?

          if [[ "$RETCODE" != "0" ]]; then
            echo "***FAULT:FATAL=The archive #{connector_url} is not a valid archive.  Cleaning up..."
            rm -rf "#{dest_file}"
          fi

          # Allow this resource to exit gracefully.  The error
          # condition will be checked and reported by the
          # check_connector_archive resource.
          #exit $RETCODE
          exit 0
      EOF
      not_if "/bin/ls #{dest_file}"
  end

  ruby_block "check_connector_archive" do
    block do
      if !File.file?("#{dest_file}")
        puts "***FAULT:FATAL=Unable to download Spark Cassandra connector archive.  Please check the log for details."

        # Raise an exception
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
    end
  end

  bash "extract_connector" do
      user "root"
      code <<-EOF
        tar -xf #{dest_file} -C #{connector_dir}

        chown -R spark:spark #{connector_dir}
      EOF
  end
else
  template "#{spark_dir}/get_connector_libs.sh" do
    source 'get_connector_libs.sh.erb'
    mode   '0755'
    owner  'spark'
    group  'spark'
    variables ({
      :spark_version => spark_version,
      :connector_dir => connector_dir,
      :nexus_url => nexus_url
    })
  end

  # The bash command normally doesn't show output, so crate a file
  # to catch the output, then echo it back.
  results_file = spark_cache_path + "/get_connector_libs.txt"

  file results_file do
    owner 'spark'
    group 'spark'
    mode  '0644'
    action :nothing
    backup false
    not_if { spark_version == "custom" }
  end

  execute "get_connector_libs" do
    command "#{spark_dir}/get_connector_libs.sh &> #{results_file}"
    not_if { spark_version == "custom" }
  end

  # Display the output so that it can go into the inductor logs, then
  # delete the file.
  ruby_block "get_connector_libs_results" do
    only_if { ::File.exists?(results_file) }
    block do
      print File.read(results_file) + "\n"
    end
    notifies :delete, "file[#{results_file}]", :immediately
  end
end
