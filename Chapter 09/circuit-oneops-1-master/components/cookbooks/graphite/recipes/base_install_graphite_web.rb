require 'uri'

# PCRE build
pcre_tarball_download = node['graphite']['pcre_download_url']
pcre_version = node['graphite']['pcre_version']
pcre_tarball = URI(pcre_tarball_download).path.split('/').last

remote_file ::File.join(Chef::Config[:file_cache_path], "#{pcre_tarball}") do
    source pcre_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}") }
end

bash "build-pcre" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar -xvf #{pcre_tarball}
      cd pcre-#{pcre_version} && ./configure && /usr/bin/make
    EOF
    not_if { ::File.exists?("#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}") }
end

pcre_dir = `ls #{Chef::Config[:file_cache_path]} | grep pcre | head -n1`
Chef::Log.info("pcre_dir: #{pcre_dir}")

# nginx build and install
nginx_tarball_download = node['graphite']['nginx_download_url']
nginx_tarball = URI(nginx_tarball_download).path.split('/').last
install_path = "/opt/nginx"

remote_file ::File.join(Chef::Config[:file_cache_path], "#{nginx_tarball}") do
    source nginx_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?(install_path) }
end

bash "build-and-install-nginx" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar -xvf #{nginx_tarball}
      cd nginx* && ./configure --with-pcre='#{Chef::Config[:file_cache_path]}/pcre-#{pcre_version}' --prefix=#{install_path} --with-debug && /usr/bin/make && /usr/bin/make install
    EOF
    not_if { ::File.exists?(install_path) }
end


# uwsgi build and install
uwsgi_tarball_download = node['graphite']['uwsgi_download_url']
uwsgi_tarball = URI(uwsgi_tarball_download).path.split('/').last
install_path = "/opt/uwsgi"

remote_file ::File.join(Chef::Config[:file_cache_path], "#{uwsgi_tarball}") do
    source uwsgi_tarball_download
    mode "0644"
    action :create
    owner "root"
    not_if { ::File.exists?(install_path) }
end

bash "build-and-install-uwsgi" do
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      tar -xvf #{uwsgi_tarball}
      cd uwsgi* && /usr/bin/make
      mkdir -p #{install_path}/{sbin,apps}
      cp uwsgi #{install_path}/sbin/
    EOF
    not_if { ::File.exists?(install_path) }
end

directory "/opt/uwsgi/log" do
    owner "root"
    group "root"
    mode "0755"
    action :create
end

# prep graphite support directories
directory "/opt/graphite/storage/log/webapp" do
    owner "apache"
    group "apache"
    mode "0755"
    action :create
end

# config files
include_recipe "graphite::nginx_graphite_configs"
