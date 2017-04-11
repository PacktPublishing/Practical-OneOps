#
# Cookbook Name:: Telegraf
# Recipe:: pkg_install.rb
#
# Copyright 2015, @WalmartLabs
#
# All rights reserved - Do Not Redistribute


telegraf_version = node.workorder.rfcCi.ciAttributes.version

#Chef::Log.info("yum-installing patch and redhat-lsb-core...")

#bash "yum-install" do
#    user "root"
#    code <<-EOF
#    yum -y install patch
#    (yum -y install redhat-lsb-core)
#    EOF
#end
#
#Chef::Log.info("done")


# ./telegraf -sample-config -input-filter cpu:mem:elasticsearch:disk -output-filter kafka > es_cpu_mem_disk_kafka.conf
# usr/bin/telegraf -config usr/bin/es_cpu_mem_disk_kafka.conf  2> telegraf.log &

 
user = "telegraf"
group = "telegraf"


user "telegraf" do
  gid "nobody"
  shell "/bin/false"
end

if node['telegraf']['run_as_root'] == 'true'
  user = "root"
  group = "root"
end


cloud = node.workorder.cloud.ciName
mirror_url_key = "telegraf"
Chef::Log.info("Getting mirror service for #{mirror_url_key}, cloud: #{cloud}")

mirror_svc = node[:workorder][:services][:mirror]
mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?
base_url = ''

# Search for graylog mirror
base_url = mirror[mirror_url_key] if !mirror.nil? && mirror.has_key?(mirror_url_key)

default_base_url ="http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/telegraf/telegraf/"
if base_url.empty?
    Chef::Log.info("#{mirror_url_key} mirror is empty for #{cloud}. Use default path:#{default_base_url}")
    base_url = default_base_url
end

Chef::Log.info("version=#{telegraf_version}")
# bug for 0.30.1 
telegraf_tgz = "telegraf-#{telegraf_version}.tar.gz"
telegraf_download_tz = base_url + "#{telegraf_version}/#{telegraf_tgz}"

Chef::Log.info("downloading #{telegraf_download_tz} ...")
# download telegraf_tz
remote_file ::File.join(Chef::Config[:file_cache_path], "#{telegraf_tgz}") do
    owner #{user}
    mode "0644"
    source telegraf_download_tz
    action :create
end
Chef::Log.info("done")

Chef::Log.info("Installing #{telegraf_tgz} ...")
# install telegraf_tgz
execute 'install telegraf tgz' do
    #user "app"
    cwd Chef::Config[:file_cache_path]
    command "tar --strip-components=2 -C / -zxf  #{telegraf_tgz}"
end


# Search for jinja mirror
jinja_template_version = '4.1-1'

jinja_default_base_url = "http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/walmartlabs/platform/jinja.template_config/#{jinja_template_version}/jinja.template_config-#{jinja_template_version}-x86_64.rpm"

jinja_mirror_url_key = "jinja-template"
jinja_base_url = ''
jinja_base_url = mirror[jinja_mirror_url_key] if !mirror.nil? && mirror.has_key?(jinja_mirror_url_key)

if jinja_base_url.empty?
    Chef::Log.error("#{jinja_mirror_url_key} mirror is empty for #{cloud}. Use default path:#{jinja_default_base_url}")
    jinja_base_url = jinja_default_base_url
end

Chef::Log.info("downloading #{jinja_base_url} ...")
remote_file ::File.join(Chef::Config[:file_cache_path], "jinja.template_config-#{jinja_template_version}-x86_64.rpm") do
    owner #{user}
    mode "0644"
    source jinja_base_url
    action :create
end

execute "Installing Template Engine" do
  command "rpm -Uvh --replacepkgs  /tmp/jinja.template_config-#{jinja_template_version}-x86_64.rpm"
end

Chef::Log.info("done mama")








# make sure /tmp is writable for everyone
bash "tmp-writable" do
    user "root"
    code <<-EOF
    (chmod a+rwx /tmp)
    EOF
end

