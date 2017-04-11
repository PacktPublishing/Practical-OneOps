full_ver = "#{node.workorder.rfcCi.ciAttributes.version}.#{node.workorder.rfcCi.ciAttributes.build_version}"
major_version = node.workorder.rfcCi.ciAttributes.version.gsub(/\..*/,"")
# tomcat reinstalls correct version for a few cases
case node.platform
when /fedora|redhat|centos/
  package "perl" do
    action :remove
  end
end

tomcat_pkgs = value_for_platform(
  ["debian","ubuntu"] => {
    "default" => ["tomcat-#{full_ver}", "tomcat-admin-webapps-#{full_ver}"]
  },
  ["centos","redhat","fedora"] => {
                                 # wmt internal rhel 6.2 repo doesnt have tomcatX-admin-webapps
                                 #"default" => [tomcat_version_name,tomcat_version_name+"-admin-webapps"]
                                 "default" => ["tomcat-#{full_ver}"]
  },
  "default" => ["tomcat-#{full_ver}"]
)

# Fix package install failure due to metadata expiry
if platform_family?("rhel")
  execute 'yum clean metadata' do
    user 'root'
    group 'root'
  end
end

tomcat_pkgs.each do |pkg|
  # debian workaround for parallel dpkg/apt-get calls
  if node.platform !~ /fedora|redhat|centos/
    ruby_block 'Check for dpkg lock' do
      block do
        sleep rand(10)
        retry_count = 0
        while system('lsof /var/lib/dpkg/lock') && retry_count < 20
          Chef::Log.warn("Found lock. Will retry package #{name} in #{node.workorder.rfcCi.ciName}")
          sleep rand(5)+10
          retry_count += 1
        end
      end
    end
    package pkg do
      Chef::Log.warn("We are installing #{pkg}")
      action :install
    end

else
  Chef::Log.warn("We are installing #{pkg}")
  bash 'Install Tomcat' do
    code <<-EOH
    sudo yum -y install tomcat-#{full_ver} tomcat-admin-webapps-#{full_ver}
    EOH
  end
 end
end

template "/etc/tomcat/server.xml" do
  source "server#{major_version}.xml.erb"
  owner "root"
  group "root"
  mode "0644"
end



template "/etc/tomcat/tomcat-users.xml" do
  source "tomcat-users.xml.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "/etc/tomcat/Catalina/localhost/manager.xml" do
  source "manager.xml.erb"
  owner "root"
  group "root"
  mode "0644"
end


directory "/etc/tomcat/policy.d" do
  action :create
  owner "root"
  group "root"
end

template "/etc/tomcat/policy.d/50local.policy" do
  source "50local.policy.erb"
  owner "root"
  group "root"
  mode "0644"
end


tomcat_env_setup = "/etc/default/tomcat"
case node["platform"]
when "centos","redhat","fedora"
  tomcat_env_setup = "/etc/sysconfig/tomcat"
end


if node["tomcat"].has_key?("environment")
  envMap = JSON.parse(node["tomcat"]["environment"])
  node.set['tomcat']['override_default_init']='false'
  node.set['tomcat']['override_default_init'] = envMap.has_key?('OVERRIDE_DEFAULT_INIT') && envMap['OVERRIDE_DEFAULT_INIT']=='true'
  Chef::Log.info("Should override_default_init : #{node.tomcat.override_default_init}")
end


template "/etc/init.d/tomcat" do
  only_if { node.tomcat.override_default_init=='true'}
  source "tomcat#{major_version}_initd.erb"
  owner "root"
  group "root"
  mode "0755"
end

template tomcat_env_setup do
  source "default_tomcat.erb"
  owner "root"
  group "root"
  mode "0644"
end

unless node["tomcat"]["access_log_dir"].start_with?("/")
  node.set['tomcat']['access_log_dir'] = "/var/log/tomcat#{major_version}/"
end
Chef::Log.info("Installation type #{node[:tomcat][:install_type]} - access log #{node[:tomcat][:access_log_dir]}")
