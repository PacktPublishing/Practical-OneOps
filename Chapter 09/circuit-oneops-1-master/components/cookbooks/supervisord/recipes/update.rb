node.set['supervisord']['inet_http_server']['user'] = node.workorder.rfcCi.ciAttributes.http_username
node.set['supervisord']['inet_http_server']['password'] = node.workorder.rfcCi.ciAttributes.http_password
node.set['supervisord']['inet_http_server']['port'] = node.workorder.rfcCi.ciAttributes.http_port
node.set['supervisord']['app_block'] = node.workorder.rfcCi.ciAttributes.program_config

template '/etc/supervisord.conf' do
	source "supervisord.conf.erb"
end