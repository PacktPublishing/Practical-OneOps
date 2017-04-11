#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: hive
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# pull in variables from shared attributes
hive_user = cia["hive_user"]
hive_install_dir = cia["hive_install_dir"]
hive_latest_dir = "#{hive_install_dir}/hive"
hive_tarball_url = cia["hive_tarball_url"]
hive_version = hive_tarball_url.split("/")[-1].split(".tar")[0]
hive_path = "#{hive_install_dir}/#{hive_version}"

# Create user
user "#{hive_user}" do
    home "/home/#{hive_user}"
    shell "/bin/bash"
    action :create
end

# add hive user to the ssh_keys group allowing cluster-wide host-based key auth
group "ssh_keys" do
    append true
    action :modify
    members "#{hive_user}"
end

# mkdir hive home dir
directory "/home/#{hive_user}" do
  owner "#{hive_user}"
  group "#{hive_user}"
  mode '0755'
  action :create
  not_if "test -d /home/#{hive_user}"
end

# mkdir logs directory
directory "/work/logs" do
  owner 'root'
  group 'root'
  mode '0777'
  action :create
  not_if "test -d /work/logs"
end

# mkdir hive install dir
directory "#{hive_install_dir}" do
    owner "root"
    group "root"
    mode  '0755'
    recursive true
    action :create
end

# mkdir Hive log directory
directory "/work/logs/hive" do
  owner "#{hive_user}"
  group "#{hive_user}"
  mode '0777'
  action :create
  not_if "test -d /work/logs/hive"
end

# install hive from tarball
bash "install_hive" do
    user "root"
    code <<-EOF
        /bin/ls #{hive_latest_dir} && /bin/rm -f #{hive_latest_dir}
        /bin/ls -d #{hive_path} && /bin/rm -rf #{hive_path}
        /usr/bin/curl "#{hive_tarball_url}" |
        /bin/tar xvz -C #{hive_install_dir}
        /bin/ln -sfn #{hive_path} #{hive_latest_dir}
        /usr/bin/chown -R #{hive_user}:#{hive_user} #{hive_path}
    EOF
    unless toBool(cia["force_hive_reinstall"])
        not_if "/bin/ls #{hive_path}"
    end
end

# if hiveserver2 is not enabled, use hive-site.xml that does not contain support for it
unless toBool(cia["enable_hiveserver2"])
    template "#{hive_path}/conf/hive-site.xml" do
        source "hive-site.xml.erb"
        owner "#{hive_user}"
        group "#{hive_user}"
        mode "0644"
        variables({
            :cia => cia
        })
        notifies :restart, 'service[hive-metastore]', :delayed
    end
end

# set hive runtime variables
template "#{hive_path}/conf/hive-env.sh" do
    source "hive-env.sh.erb"
    owner "#{hive_user}"
    group "#{hive_user}"
    mode "0644"
end

# create symlink to point hive to the latest version
link "#{hive_install_dir}/hive" do
    to hive_path
end

# set hive environment variables
template '/etc/profile.d/hive.sh' do
    source 'hive.sh.erb'
    owner "root"
    group "root"
    mode 0644
    variables({
              :hive_home => "#{hive_install_dir}/hive"
              })
end

# get resource manager ipaddress- this is defined in the helper library
prmNode, srmNode = getRm()

# update templated configs
%w{core-site.xml}.each do |xml_config|
    template "#{hive_latest_dir}/conf/#{xml_config}" do
        source "#{xml_config}.erb"
        owner "#{hive_user}"
        group "#{hive_user}"
        mode '0644'
        variables({
            :primaryResourceManager => prmNode,
            :cia => cia
        })
        notifies :restart, 'service[hive-metastore]', :delayed
    end
end

# log4j2
cookbook_file "#{hive_latest_dir}/conf/hive-log4j2.properties" do
    source "hive-log4j2.properties"
    owner "#{hive_user}"
    group "#{hive_user}"
    mode '0644'
end

# startup scripts for hive-init
directory "#{hive_path}/conf/startup-hql" do
  owner "#{hive_user}"
  group "#{hive_user}"
  mode '0755'
  action :create
end

# download scripts from the given url
hive_startup_hql_scripts = eval cia["hive_startup_hql_scripts"]
unless hive_startup_hql_scripts.empty?
    hive_startup_hql_scripts.each do |hql_script_loc|
        if isValidUrl(hql_script_loc)
            hql_script = hql_script_loc.split("/")[-1]
            remote_file "#{hive_path}/conf/startup-hql/#{hql_script}" do
                source "#{hql_script_loc}"
                owner "#{hive_user}"
                group "#{hive_user}"
                mode '0755'
                action :create
            end
        else
            puts "ERROR: #{hql_script_loc} is not a valid URL, skipping"
        end
    end
end

# hive metastore init script
cookbook_file "/etc/init.d/hive-metastore" do
    source "hive-metastore.init"
    owner 'root'
    group 'root'
    mode '0755'
end

# enale hive metastore service only if specified
service "hive-metastore" do
    if toBool(cia["enable_thrift_metastore"])
        action [:enable, :start]
    else
        action [:disable, :stop]
    end
    supports :restart => true, :reload => true
end

# set up keystore/trustore and hiveserver2 if specified
if toBool(cia["enable_hiveserver2"])

    # depending on if passwords already exist, use existing password or generate new random password
    private_pass, public_pass = getKeystorePass()

    # Create keystore directory
    directory "#{hive_latest_dir}/conf/keystore" do
        owner "#{hive_user}"
        group "#{hive_user}"
        mode '0755'
        action :create
    end

    # generate keystore
    bash "create keystore" do
        user "#{hive_user}"
        cwd "#{hive_latest_dir}/conf/keystore"
        code <<-EOF
            /usr/bin/keytool -genkeypair -alias #{node.hostname} -keystore #{node.hostname}.keystore -keyalg "RSA" -keysize 4096 -dname "CN=$(hostname -f),O=Hadoop" -storepass #{private_pass} -keypass #{private_pass} -validity 365
            /usr/bin/keytool -exportcert -keystore #{node.hostname}.keystore -alias #{node.hostname} -storepass #{private_pass} -file #{node.hostname}.cer
            /usr/bin/keytool -importcert -keystore #{node.hostname}.truststore -alias #{node.hostname} -storepass #{public_pass} -file #{node.hostname}.cer -noprompt
        EOF
        not_if "/bin/ls #{hive_latest_dir}/conf/keystore/#{node.hostname}.keystore"
    end

    # public truststore password
    file "#{hive_latest_dir}/conf/keystore/pub_truststore_pass" do
        content "#{public_pass}"
        owner "#{hive_user}"
        group "#{hive_user}"
        mode '0644'
    end

    # deploy hive-site.xml with hiveserver2 properties
    template "#{hive_path}/conf/hive-site.xml" do
        source "hive-site.xml.erb"
        owner "#{hive_user}"
        group "#{hive_user}"
        mode "0644"
        variables({
            :cia => cia,
            :private_pass => private_pass,
            :keystore_loc => "#{hive_latest_dir}/conf/keystore/#{node.hostname}.keystore"
        })
        if toBool(cia["enable_thrift_metastore"])
            notifies :restart, 'service[hive-metastore]', :delayed
        end
        notifies :restart, 'service[hive-hiveserver2]', :delayed
    end

    # deploy hiveserver2 init script
    cookbook_file "/etc/init.d/hive-hiveserver2" do
        source "hive-hiveserver2.init"
        owner 'root'
        group 'root'
        mode '0755'
    end

    # add hiveserver2 to chkconfig and start service
    service "hive-hiveserver2" do
        action [:enable, :start]
        supports :restart => true, :reload => true
    end

end
