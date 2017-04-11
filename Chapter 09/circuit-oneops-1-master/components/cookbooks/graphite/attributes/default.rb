#
# Cookbook Name:: graphite
# Attributes:: default
#

default['graphite']['version'] = "0.9.15"

default['graphite']['install_path'] = "/opt/graphite"
default['graphite']['replication_factor'] = "1"

default['graphite']['download_base_url'] = "https://github.com/graphite-project/"

default['graphite']['account']['user'] = "graphite"
default['graphite']['account']['group'] = "graphite"
default['graphite']['dir']['log_dir'] = "/var/log/graphite"
default['graphite']['dir']['whisper_dir'] = "/opt/graphite/storage/whisper"

default['graphite']['pcre_download_url'] = "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.tar.gz"
default['graphite']['uwsgi_download_url'] = "https://github.com/unbit/uwsgi/archive/2.0.14.tar.gz"
default['graphite']['nginx_download_url'] = "http://nginx.org/download/nginx-1.7.6.tar.gz"

default['graphite']['pcre_version'] = "8.39"