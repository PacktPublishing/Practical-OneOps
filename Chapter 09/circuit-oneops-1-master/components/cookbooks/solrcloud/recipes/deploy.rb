#
# Cookbook Name :: solrcloud
# Recipe :: deploy.rb
#
# The recipe deploys the solr.war in tomcat web server.
#

if node['solr_version'].start_with? "4."
  Chef::Log.info('Tomcat log4j.properties file')
  template node['tomcat']['dir']+"/lib/log4j.properties" do
    source 'log4j.properties.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    action :create_if_missing
  end

  Chef::Log.info('deploy solr.war in tomcat')
  bash 'deploy_solr_war' do  
    code <<-EOH
      cd #{node['user']['dir']}
      sudo rm -rf deploy-*.txt
      echo #{node['solr_version']} > deploy-#{node['solr_version']}.txt
      rm -rf #{node['tomcat']['dir']}/webapps/solr
      rm -rf #{node['tomcat']['dir']}/webapps/solr.war
      sudo cp solr.war #{node['tomcat']['dir']}/webapps/
    EOH
    notifies :run, 'execute[notify-tomcat-restart]', :immediately
    not_if { ::File.exists?(node['user']['dir']+"/deploy-"+node['solr_version']+".txt") }
  end

  Chef::Log.info('Create the solr.xml in Catalina/localhost')
  template node['tomcat']['dir']+"/conf/Catalina/localhost/solr.xml" do
    source 'solr.xml.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0777'
    mode '0777'
    notifies :run, 'execute[notify-tomcat-restart]', :immediately
    not_if { ::File.exists?(node['tomcat']['dir']+"/conf/Catalina/localhost/solr.xml") }
  end

  execute 'notify-tomcat-restart' do
    command "service tomcat#{node['tomcatversion']} restart"
    user "root"
    action :run
    only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}") }
  end

end


