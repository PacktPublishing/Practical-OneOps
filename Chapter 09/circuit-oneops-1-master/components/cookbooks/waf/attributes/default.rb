default[:waf][:version] = "2.6.3"

# Where the various parts of apache are
case platform
when "redhat","centos","fedora","suse"
  set[:apache][:dir]     = "/etc/httpd"
  set[:apache][:log_dir] = "/var/log/httpd"
  set[:apache][:user]    = "apache"
  set[:apache][:binary]  = "/usr/sbin/httpd"
  set[:apache][:icondir] = "/var/www/icons/"
  set[:apache][:cache_dir] = "/var/cache/httpd"
when "debian","ubuntu"
  set[:apache][:dir]     = "/etc/apache2"
  set[:apache][:log_dir] = "/var/log/apache2"
  set[:apache][:user]    = "www-data"
  set[:apache][:binary]  = "/usr/sbin/apache2"
  set[:apache][:icondir] = "/usr/share/apache2/icons"
  set[:apache][:cache_dir] = "/var/cache/apache2"
when "arch"
  set[:apache][:dir]     = "/etc/httpd"
  set[:apache][:log_dir] = "/var/log/httpd"
  set[:apache][:user]    = "http"
  set[:apache][:binary]  = "/usr/sbin/httpd"
  set[:apache][:icondir] = "/usr/share/httpd/icons"
  set[:apache][:cache_dir] = "/var/cache/httpd"
else
  set[:apache][:dir]     = "/etc/apache2"
  set[:apache][:log_dir] = "/var/log/apache2"
  set[:apache][:user]    = "www-data"
  set[:apache][:binary]  = "/usr/sbin/apache2"
  set[:apache][:icondir] = "/usr/share/apache2/icons"
  set[:apache][:cache_dir] = "/var/cache/apache2"
end

# nginx
case platform
when "debian","ubuntu"
  set[:nginx][:dir]     = "/etc/nginx"
  set[:nginx][:log_dir] = "/var/log/nginx"
  set[:nginx][:user]    = "www-data"
  set[:nginx][:binary]  = "/usr/sbin/nginx"
else
  set[:nginx][:dir]     = "/etc/nginx"
  set[:nginx][:log_dir] = "/var/log/nginx"
  set[:nginx][:user]    = "nginx"
  set[:nginx][:binary]  = "/usr/sbin/nginx"
end