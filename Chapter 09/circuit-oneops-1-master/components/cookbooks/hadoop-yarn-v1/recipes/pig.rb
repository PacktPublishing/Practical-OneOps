#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: pig
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# pull in variables from shared attributes
pig_user = cia["pig_user"]
pig_install_dir = cia["pig_install_dir"]
pig_latest_dir = "#{pig_install_dir}/pig"
pig_tarball_url = cia["pig_tarball_url"]
pig_version = pig_tarball_url.split("/")[-1].split(".tar")[0]
pig_path = "#{pig_install_dir}/#{pig_version}"

# Create pig user
user "#{pig_user}" do
    home "/home/#{pig_user}"
    shell "/bin/bash"
    action :create
end

# mkdir pig home dir
directory "/home/#{pig_user}" do
    owner "#{pig_user}"
    group "#{pig_user}"
    mode '0755'
    action :create
    not_if "test -d /home/#{pig_user}"
end

# Create logs directory
directory "/work/logs" do
    owner 'root'
    group 'root'
    mode '0777'
    action :create
    not_if "test -d /work/logs"
end

# create pig install dir
directory "#{pig_install_dir}" do
    owner "root"
    group "root"
    mode  '0755'
    recursive true
    action :create
end

# Create Pig log directory
directory "/work/logs/pig" do
      owner "#{pig_user}"
      group "#{pig_user}"
      mode '0777'
      action :create
      not_if "test -d /work/logs/pig"
end

# install pig from tarball
bash "install_pig" do
    user "root"
    code <<-EOF
        /bin/ls #{pig_latest_dir} && /bin/rm -f #{pig_latest_dir}
        /bin/ls -d #{pig_path} && /bin/rm -rf #{pig_path}
        /usr/bin/curl "#{pig_tarball_url}" |
        /bin/tar xz -C #{pig_install_dir}
        /bin/ln -sfn #{pig_path} #{pig_latest_dir}
        /usr/bin/chown -R #{pig_user}:#{pig_user} #{pig_path}
    EOF
    unless toBool(cia["force_pig_reinstall"])
        not_if "/bin/ls #{pig_path}"
    end
end

# set pig environment variables
template '/etc/profile.d/pig.sh' do
    source 'pig.sh.erb'
    owner "root"
    group "root"
    mode 0644
    variables({ :pig_home => "#{pig_install_dir}/pig" })
end
