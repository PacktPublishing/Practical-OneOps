#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: binary_install
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# mkdir hadoop home dir
hadoop_install_dir = cia["hadoop_install_dir"]
directory "#{hadoop_install_dir}" do
    owner 'root'
    group 'root'
    mode  '0755'
    recursive true
    action :create
end

# mkdir tmp dir
swift_tmp_dir = cia["swift_tmp_dir"]
directory "#{swift_tmp_dir}" do
    owner 'root'
    group 'root'
    mode  '1777'
    recursive true
    action :create
end

# get the location of the hadoop tarball
hadoop_tarball = cia["yarn_tarball"]
# get the version number out of the filename of the tarball
hadoop_version = hadoop_tarball.split("/")[-1].split(".tar")[0]
hadoop_latest_dir = "#{hadoop_install_dir}/hadoop"

# install hadoop from tarball and symlink hadoop to the latest code deployed
bash "install_hadoop" do
    user "root"
    code <<-EOF
        /bin/ls #{hadoop_latest_dir} && /bin/rm -f #{hadoop_latest_dir}
        /bin/ls -d #{hadoop_install_dir}/#{hadoop_version} && /bin/rm -rf #{hadoop_install_dir}/#{hadoop_version}
        /usr/bin/curl "#{hadoop_tarball}" |
        /bin/tar xvz -C #{hadoop_install_dir}
        /bin/ln -sfn #{hadoop_install_dir}/#{hadoop_version} #{hadoop_latest_dir}
    EOF
    # this condition will force a re-install of the tarball regardless of installed version
    unless toBool(cia["force_yarn_reinstall"])
        not_if "/bin/ls #{hadoop_install_dir}/#{hadoop_version}"
    end
end

# move hadoop log directory to /work/logs/hadoop
directory "/work/logs/hadoop" do
  owner 'root'
  group 'root'
  mode '0777'
  action :create
  recursive true
  not_if "test -d /work/logs/hadoop"
end

directory "#{hadoop_install_dir}/hadoop/logs" do
  action :delete
  only_if "test ! -h #{hadoop_install_dir}/hadoop/logs && test -d #{hadoop_install_dir}/hadoop/logs"
end

link "#{hadoop_install_dir}/hadoop/logs" do
    to "/work/logs/hadoop"
end

# create user to run services as
hadoop_user = cia["hadoop_user"]
user "#{hadoop_user}" do
  shell "/bin/bash"
  action :create
end

# add users to ssh_keys group to allow host-based auth
group "ssh_keys" do
    append true
    action :modify
    members "#{hadoop_user}"
end

# chown hadoop dir to hadoop user
bash "chown_hadoop_dir" do
    user "root"
    code <<-EOF
        /bin/chown -R #{hadoop_user}:#{hadoop_user} #{hadoop_install_dir}/#{hadoop_version}
    EOF
    not_if "/bin/ls -ld #{hadoop_install_dir}/#{hadoop_version} | awk '{print $3}' | grep -q #{hadoop_user}"
end

# set hadoop env
template '/etc/profile.d/hadoop.sh' do
    source 'hadoop.sh.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables({
        :cia => cia
    })
end

# mkdir pid dir
directory "/var/run/hadoop" do
    owner "#{hadoop_user}"
    group "#{hadoop_user}"
    mode  '0755'
    recursive true
    action :create
end

# deploy any additional libraries specified in the platform
additional_libraries = cia["additional_libraries"].split(',')
additional_libraries.each do | full_library_source_path |
    additional_library = full_library_source_path.split("/")[-1]

    remote_file "#{hadoop_latest_dir}/share/hadoop/common/lib/#{additional_library}" do
        source "#{full_library_source_path}"
        owner "#{hadoop_user}"
        group "#{hadoop_user}"
        mode "0644"
        action :create
    end
end

# get resource manager ipaddress- this is defined in the helper library
prmNode, srmNode = getRm()

# create directories specified in hdfs-site.xml for data and name dirs
hdfs_namenode_name_dir = cia["hdfs_namenode_name_dir"]
directory "#{hdfs_namenode_name_dir}" do
    owner "#{hadoop_user}"
    group "#{hadoop_user}"
    mode  '0755'
    recursive true
    action :create
end

hdfs_datanode_data_dir = cia["hdfs_datanode_data_dir"]
directory "#{hdfs_datanode_data_dir}" do
    owner "#{hadoop_user}"
    group "#{hadoop_user}"
    mode  '0755'
    recursive true
    action :create
end

# figure out if node is a data node
componentName = node.workorder.rfcCi.ciName
is_dn = false
if componentName =~ /^dn/
    is_dn = true
end

# deploy templated configs
map_memory, reduce_memory, container_memory, total_available_memory_in_mb = getMemoryConfigs()
cores = getCoreConfig()
%w{
mapred-site.xml
hadoop-env.sh
hdfs-site.xml
core-site.xml
jets3t.properties
yarn-site.xml}.each do |xml_config|
    template "#{hadoop_latest_dir}/etc/hadoop/#{xml_config}" do
        source "#{xml_config}.erb"
        owner "#{hadoop_user}"
        group "#{hadoop_user}"
        mode '0644'
        variables({
            :is_dn => is_dn,
            :cores => cores,
            :map_memory => map_memory,
            :reduce_memory => reduce_memory,
            :container_memory => container_memory,
            :total_available_memory_in_mb => total_available_memory_in_mb,
            :primaryResourceManager => prmNode,
            :secondaryResourceManager => srmNode,
            :cia => cia
        })
    end
end

# deploy static configs
cookbook_file "#{hadoop_latest_dir}/libexec/hadoop-config.sh" do
    source "hadoop-config.sh"
    owner "#{hadoop_user}"
    group "#{hadoop_user}"
    mode '0755'
end

%w{
log4j.properties
mapred-queues.xml}.each do |xml_config|
    cookbook_file "#{hadoop_latest_dir}/etc/hadoop/#{xml_config}" do
        source "#{xml_config}"
        owner "#{hadoop_user}"
        group "#{hadoop_user}"
        mode '0644'
    end
end

# hadoop-metrics2.properties for ganglia
template "#{hadoop_latest_dir}/etc/hadoop/hadoop-metrics2.properties" do
    source "hadoop-metrics2.properties.erb"
    owner "#{hadoop_user}"
    group "#{hadoop_user}"
    variables({
        :cia => cia
    })
    mode '0664'
end

# openstack properties
template "/etc/profile.d/openstack_properties.sh" do
    source "openstack_properties.sh.erb"
    owner "root"
    group "root"
    variables({
        :cia => cia
    })
    mode '0664'
end
