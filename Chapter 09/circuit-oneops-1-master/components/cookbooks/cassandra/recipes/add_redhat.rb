
package "jna"


version = node.workorder.rfcCi.ciAttributes.version

if (Gem::Version.correct?(version))
  if (Gem::Version.new(version).prerelease?)
    Chef::Log.warn("Warning, You are using prerelease versions #{version}. It is non recommended to use prerelease versions for production use")
  else
    Chef::Log.info("Version Selected #{version} ")

  end
else
  Chef::Log.error("unsupported version: #{version}")
  puts "***FAULT:FATAL=Unsupported version: #{version}"
  exception = Exception.new("no backtrace")
  exception.set_backtrace("")
  raise exception
end

sub_dir = "/cassandra/#{version}/"
tgz_file = "apache-cassandra-#{version}-bin.tar.gz"

tmp = Chef::Config[:file_cache_path]

# try component mirrors first, if empty try cloud mirrors, if empty use cookbook mirror attribute
source_list = JSON.parse(node.cassandra.mirrors).map!{ |mirror| "#{mirror}/#{sub_dir}#{tgz_file}"}
if source_list.empty?
  cloud_name = node[:workorder][:cloud][:ciName]
  mirrors = []
  if node[:workorder][:services].has_key? "mirror"
    mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  end
  source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}#{sub_dir}#{tgz_file}" }
end
source_list = [ node['cassandra']['src_mirror'] ] if source_list.empty?
source_list = [ "http://archive.apache.org/dist" ] if source_list.empty?
dest_file = "#{tmp}/#{tgz_file}"

shared_download_http source_list.join(",") do
  path dest_file
  action :create
  if node[:cassandra][:checksum] && !node[:cassandra][:checksum].empty?
    checksum node[:cassandra][:checksum]
  end
end

install_dir = node.workorder.rfcCi.ciAttributes.has_key?("install_dir") ? node.workorder.rfcCi.ciAttributes.install_dir : '/opt'

directory "#{install_dir}" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

untar_dir = "#{install_dir}/apache-cassandra-#{version}"


execute "untar_cassandra" do
  command "tar -zxf #{dest_file}; rm -fr /opt/cassandra ; ln -sf #{untar_dir} /opt/cassandra"
  cwd "#{install_dir}"
end

execute "ln -fs /usr/share/java/jna.jar /opt/cassandra/lib" do
  only_if { ::File.exist?("/usr/share/java/jna.jar") }
end

include_recipe "cassandra::add_user_dirs"


template "/opt/cassandra/conf/cassandra-env.sh" do
  source "cassandra-env.sh.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/init.d/cassandra" do
  source "initd.erb"
  owner "root"
  group "root"
  mode 0700
end

include_recipe "cassandra::log4j_directives"
