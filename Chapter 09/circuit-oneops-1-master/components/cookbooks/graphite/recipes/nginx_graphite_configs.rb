# uwsgi.service
cookbook_file "/usr/lib/systemd/system/uwsgi.service" do
    source "uwsgi.service"
    owner "root"
    group "root"
    mode "0644"
end

# nginx.service
cookbook_file "/usr/lib/systemd/system/nginx.service" do
    source "nginx.service"
    owner "root"
    group "root"
    mode "0644"
end

bash "make-memcached-auto-start" do
   user "root"
   code <<-EOF
     chkconfig --level 2345 memcached on
   EOF
end

service "memcached" do
  service_name 'memcached'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
end

# logrotate for nginx
cookbook_file "/etc/logrotate.d/nginx" do
    source "logrotate-nginx"
    owner "root"
    group "root"
    mode "0644"
end

# nginx.conf for graphite
template "/opt/nginx/conf/nginx.conf" do
    source "nginx_graphite.conf.erb"
    owner "root"
    group "root"
    mode "0644"
end

# uwsgi config for graphite
template "/opt/uwsgi/apps/graphite.ini" do
    source "graphite-uwsgi.ini.erb"
    owner "root"
    group "root"
    mode "0644"
end

# create /opt/nginx/cache
directory "/opt/nginx/cache" do
   owner "root"
   group "root"
   mode '0755'
   action :create
end

bash "move-and-chown-cache" do
   user "root"
   code <<-EOF
      cp -r /opt/nginx/cache/ /data
      (rm -rf /opt/nginx/cache)
      (ln -s /data/cache/ /opt/nginx/cache)
   EOF
end
