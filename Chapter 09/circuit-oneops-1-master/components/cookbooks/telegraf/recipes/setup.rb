# Cookbook Nameo: telegraf
# Recipe:: setup.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute




configure = node['telegraf']['configure']
configdir = node['telegraf']['configdir']
name = node.workorder.payLoad.RealizedAs[0].ciName
user = "telegraf"
group = "nobody"

if node['telegraf']['run_as_root'] == 'true'
  user = "root"
  group = "root"
end

telegraf_conf_variables = {
   :configure => configure,
}


telegraf_cmd_variables = {
   :configdir => configdir,
   :name => name,
   :user => user,
   :group => group
}

if(configure.nil? || configure.empty?)
   Chef::Log.info("config is empty, use default")
   execute 'Copying telegraf config file' do
    command "cp /etc/telegraf/telegraf.conf  /tmp/#{name}.conf"
   end
   execute 'change permission for telegraf.conf' do
    command "chown #{user}  /tmp/#{name}.conf"
   end
else
  # generate conf file for telegraf
  template "/tmp/#{name}.1" do
      source "telegraf.conf.erb"
      owner #{user}
      group #{group}
      mode  '0664'
      variables telegraf_conf_variables
  end

  #  run the template engine
  execute 'Running Template' do
     user #{user}
     command "source /etc/profile.d/oneops.sh;/usr/bin/config_template  /tmp/#{name}.1 > /tmp/#{name}.conf"
  end
end

# create the conf  dir
directory "#{configdir}" do
    owner #{user}
    group #{group}
    recursive true
    mode '0755'
    action :create
end

execute 'Copying telegraf config file' do
    command "cp /tmp/#{name}.conf  #{configdir}/#{name}.conf"
end



initd_filename = 'telegraf'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else 
  initd_filename = initd_filename + "_" + name
end

template "/etc/init.d/#{initd_filename}" do
  source "initd.erb"
  owner #{user}
  group #{group}
  mode 0755
  variables telegraf_cmd_variables
end

execute "chkconfig --add /etc/init.d/#{initd_filename}" do
  returns [0,1]
end

directory "/var/log/telegraf/" do
    owner #{user}
    group #{group}
    recursive true
    mode '0755'
    action :create
end

execute "change owner /var/log/telegraf/" do
  command "chown -R #{user} /var/log/telegraf/"
end

execute "change group /var/log/telegraf/" do
  command "chgrp -R #{group} /var/log/telegraf/"
end


#cookbook_file '/opt/nagios/libexec/check_telegraf' do
#  source 'check_telegraf.rb'
#  owner 'root'
#  group 'root'
#  mode 0755
#end
     






