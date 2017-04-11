default[:supervisord][:pip] = "easy_install pip"

default[:supervisord][:unix_http_server][:enabled]  = true
default[:supervisord][:unix_http_server][:file] = "/tmp/supervisor.sock"
default[:supervisord][:unix_http_server][:chmod] = "0700"

default[:supervisord][:inet_http_server][:enabled]  = true
default[:supervisord][:inet_http_server][:port] = 9001
default[:supervisor][:inet_http_server][:user] = "admin"
default[:supervisor][:inet_http_server][:password] = "admin"

default[:supervisord][:supervisord][:logfile] = "/tmp/supervisord.log"
default[:supervisord][:supervisord][:logfile_maxbytes] = "50MB"
default[:supervisord][:supervisord][:logfile_backups] = 10
default[:supervisord][:supervisord][:loglevel] = "info"
default[:supervisord][:supervisord][:pidfile] = "/tmp/supervisord.pid"
default[:supervisord][:supervisord][:nodaemon] = false
default[:supervisord][:supervisord][:minfds] = 1024
default[:supervisord][:supervisord][:minprocs] = 200

default[:supervisord][:supervisorctl][:serverurl] = "unix:///tmp/supervisor.sock"

default[:supervisord][:app_block] = ""