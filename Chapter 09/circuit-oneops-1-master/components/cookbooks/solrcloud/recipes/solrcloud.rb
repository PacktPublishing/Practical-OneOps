#
# Cookbook Name :: solrcloud
# Recipe :: solrcloud.rb
#
# The recipe extracts the solr distribution, copies the WEB-INF/lib/ jars to solr-war-lib folder and sets up the solrcloud
#

extend SolrCloud::Util

# Wire solrcloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

ci = node.workorder.rfcCi.ciAttributes;
solr_base_url = ci['solr_url']
solr_package_type = ci['solr_package_type']
solr_format = ci['solr_format']

solr_download_path = "/tmp";
solr_file_name = "#{solr_package_type}-"+node['solr_version']+".#{solr_format}"
solr_file_woext = "#{solr_package_type}-"+node['solr_version']
solr_url = "#{solr_base_url}/#{solr_package_type}/"+node['solr_version']+"/#{solr_file_name}"
solr_filepath = "#{solr_download_path}/#{solr_file_name}"


Chef::Log.info("Download solr from : #{solr_url}")
remote_file solr_filepath do
  source "#{solr_url}"
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

if node['solr_version'].start_with? "4."

  solr_extract_path = "#{node['solr_download_path']}/extract"
  solr_extract_war_path = "#{solr_extract_path}/extract-war"
  solr_war_lib = "#{node['user']['dir']}/solr-war-lib"
  solr_config = "#{node['user']['dir']}/solr-config"
  solr_cores = "#{node['user']['dir']}/solr-cores"
  solr_default_dir = "#{solr_config}/default"


  ["#{solr_war_lib}" ,"#{solr_config}","#{solr_default_dir}","#{solr_cores}","#{solr_extract_path}" ].each { |dir|
    Chef::Log.info("creating #{dir} for users")
    directory dir do
      not_if { ::File.directory?(dir) }
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  }

  Chef::Log.info('UnPack solr.war and extract the WEB-INF/lib to /app/solr-war-lib/ folder')
  bash 'unpack_solr_war' do
    code <<-EOH
      cd #{node['user']['dir']}
      rm -rf solr-*.txt
      echo #{node['solr_version']} > solr-#{node['solr_version']}.txt
      mkdir #{solr_extract_path}
      mv /tmp/#{solr_file_name} #{solr_extract_path}
      cd #{solr_extract_path}
      mkdir extract-war
      tar -xf #{solr_file_name}
      cp #{solr_file_woext}/dist/#{solr_file_woext}.war ./extract-war
      cd ./extract-war
      jar xvf #{solr_file_woext}.war
      rm -rf #{node['user']['dir']}/solr-war-lib/*
      rm -rf #{node['user']['dir']}/solr.war
      cp #{solr_extract_war_path}/WEB-INF/lib/* #{solr_war_lib}
      cp #{solr_file_woext}.war solr.war
      cp solr.war #{node['user']['dir']}
      rm -rf #{node['user']['dir']}/solr-config/default/*
      cp -irf #{solr_extract_path}/#{solr_file_woext}/example/solr/collection1/conf/* #{node['user']['dir']}/solr-config/default/
      cp #{solr_extract_path}/#{solr_file_woext}/example/lib/ext/*.jar #{solr_war_lib}
      cp #{solr_extract_path}/#{solr_file_woext}/example/lib/ext/*.jar #{node['tomcat']['dir']}/lib
    EOH
    not_if { ::File.exists?("#{node['user']['dir']}/solr-#{node['solr_version']}.txt") }
  end

  bash "update_zookeeper_string" do
    code <<-EOH
      grep -q -F 'zkHost' #{node['tomcat']['dir']}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{node['zk_host_fqdns']}\"' >> #{node['tomcat']['dir']}/bin/setenv.sh
    EOH
  end

  Chef::Log.info('Create/Update the solr.xml in /solr-cores')
  cookbook_file "#{node['user']['dir']}/solr-cores/solr.xml" do
    source "solr.xml"
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    action :create_if_missing
  end

  execute 'notify-tomcat-restart' do
    command "service tomcat#{node['tomcatversion']} restart"
    user "root"
    action :run
    only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}") }
  end

end


if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.")

  solr_war_lib_dir = node['user']['dir']+"/solr-war-lib"+node['solrmajorversion']
  solr_config_dir = node['user']['dir']+"/solr-config"+node['solrmajorversion']


  ["#{solr_war_lib_dir}" ,"#{solr_config_dir}" ].each { |dir|
    Chef::Log.info("creating #{dir} for users")
    directory dir do
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  }

  bash "install_solr_and_copy_jars" do
    code <<-EOH
      cd #{solr_download_path}
      tar -xf #{solr_file_name}
      cd #{solr_file_woext}/bin
      chmod 777 install_solr_service.sh
      sudo ./install_solr_service.sh #{solr_download_path}/#{solr_file_name} -i #{node['installation_dir_path']} -d #{node['data_dir_path']} -u #{node['solr']['user']} -p #{node['port_no']} -s solr#{node['solrmajorversion']}
      rm -rf /etc/default/solr#{node['solrmajorversion']}.in.sh
      rm -rf #{node['data_dir_path']}/log4j.properties
      cd #{node['installation_dir_path']}/solr#{node['solrmajorversion']}/server/
      cp lib/ext/* #{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}
      cp solr-webapp/webapp/WEB-INF/lib/* #{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}
      echo #{node['solr_version']} > #{node['user']['dir']}/solr-#{node['solr_version']}.txt
    EOH
    not_if { ::File.exists?(node['user']['dir']+"/solr-"+node['solr_version']+".txt") }
  end

  Chef::Log.info('log4j.properties file')
  template "#{node['data_dir_path']}/log4j.properties" do
    source 'log4j.properties.solr.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    action :create_if_missing
  end

  Chef::Log.info('Create solr.in.sh file')
  template "#{node['data_dir_path']}/solr.in.sh" do
    source 'solr.in.sh.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
  end


  Chef::Log.info('Create solr service')
  template "/etc/init.d/solr#{node['solrmajorversion']}" do
    source 'solr.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
  end

  execute 'solr-restart' do
    command "service solr#{node['solrmajorversion']} restart"
    user "root"
    action :run
    only_if { ::File.exists?("/etc/init.d/solr#{node['solrmajorversion']}") }
  end

end


if !node['config_name'].empty?
  downloadconfig(node['solr_version'],node['zk_host_fqdns'],node['config_name'])
  uploaddefaultconfig(node['solr_version'],node['zk_host_fqdns'],node['config_name'])
end


Chef::Log.info("Copying solrprocess script")
template "/opt/nagios/libexec/check_solrprocess.sh" do
  source "check_solrprocess.sh.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  action :create_if_missing
end


