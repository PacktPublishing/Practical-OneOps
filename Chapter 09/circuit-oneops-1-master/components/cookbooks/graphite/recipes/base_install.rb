
# disable epel repo
%w{epel epel-testing}.each do |epel_repo|
    if ::File.exist?("/etc/yum.repos.d/#{epel_repo}.repo")
        ruby_block "disable #{epel_repo} repo" do
            block do
                ::File.rename("/etc/yum.repos.d/#{epel_repo}.repo", "/etc/yum.repos.d/#{epel_repo}.repo.disabled")
            end
        end
    end
end


%w{ 
autoconf
automake
bitmap
django
django-tagging
gcc
gcc-c++
git
memcached
mod_wsgi
openssl-devel
pycairo
pyOpenSSL
python
python-crypto
python-ldap
python-memcached

python-twisted-core


python-zope-interface
python-whisper
xorg-x11-xbitmaps
python-pip.noarch
python-devel}.each do |pkg|
    yum_package pkg do
       action :install
    end
end

bash "clean-old-graphite-python-executable" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
      rm -rf /opt/graphite/bin/
      rm -rf /opt/graphite/lib/
      rm -rf /opt/graphite/webapp/
  EOF
end

Chef::Log.info("Removed old Graphite python executable.")

# download and install graphite components
%w{
graphite-web
carbon
whisper}.each do |component|
    component_version_str = component + "-" + node['graphite']['version']
    Chef::Log.info("component_version_str: #{component_version_str}")
    remote_file ::File.join(Chef::Config[:file_cache_path], "#{component_version_str}.tar.gz") do
        owner "root"
        mode "0644"
        source node['graphite']['download_base_url'] + component + "/archive/" + node['graphite']['version'] + ".tar.gz"
        action :create
    end
    
    bash "build-and-install-#{component_version_str}" do
        cwd Chef::Config[:file_cache_path]
        code <<-EOF
        
        tar -zxvf #{component_version_str}.tar.gz
        
        rm #{component_version_str}.tar.gz
        
        cd #{component_version_str} && python setup.py install
        
        rm -rf /tmp/#{component_version_str}
        EOF
    end

end

Chef::Log.info("Graphite installation is done.")

# install additional python packages and Graphite tools
%w{
argparse
pytz
graphite-dashboardcli
carbonate}.each do |pkg|
    easy_install_package pkg do
        action :install
    end
end

Chef::Log.info("Installed additional python packages and Graphite tools.")

# add graphite user
include_recipe "graphite::user"

# web configs
include_recipe "graphite::web"

# carbon configs
include_recipe "graphite::carbon"

# bootstrap django db
django_db = "/opt/graphite/storage/graphite.db"

template "/opt/graphite/webapp/graphite/initial_data.json" do
    source "init_data.json.erb"
    owner "graphite"
    group "graphite"
    mode "0644"
    not_if { ::File.exists?(django_db) } 
end

execute "syncdb" do
    cwd "/opt/graphite/webapp/graphite"
    command "python manage.py syncdb --noinput"
    not_if { ::File.exists?(django_db) } 
end


user "apache" do
   system true
   home "/home/apache"
   shell "/bin/bash"
   action :create
   not_if { ::File.exists?(django_db) }
end

file "/opt/graphite/storage/graphite.db" do
    owner "apache"
    group "apache"
    mode "0644"
    not_if { ::File.exists?(django_db) }
end

bash "move-and-chown-storage" do
   user "root"
   code <<-EOF
        cp -r /opt/graphite/storage /data
	(rm -rf /opt/graphite/storage)
	(ln -s /data/storage/ /opt/graphite/storage)
	(chown -R apache:apache /opt/graphite/storage/)
   EOF
   not_if { ::File.exists?("/data/storage/") }
end
