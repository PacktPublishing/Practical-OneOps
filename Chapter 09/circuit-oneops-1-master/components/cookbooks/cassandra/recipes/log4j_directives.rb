#
# Cookbook Name:: cassandra
# Recipe:: log4j_directives
#

require 'json'

log4j_attrs = {
  "log4j.appender.R.File" => "/var/log/cassandra/system.log",
  "log4j.appender.R.maxFileSize" => "10MB",
  "log4j.appender.R.layout.ConversionPattern" => "%-5level [%thread] %date{ISO8601} %F:%L - %msg%n",
  "log4j.appender.stdout.layout.ConversionPattern" => "%-5level %date{HH:mm:ss,SSS} %msg%n",
  "log4j.rootLogger" => "INFO,stdout,R",
  "com.thinkaurelius.thrift" => "ERROR"
}

log_levels = ['ALL','TRACE','DEBUG','INFO','WARN','ERROR','OFF']

ver = node.workorder.rfcCi.ciAttributes.version.to_f

ruby_block 'update_log4j_directives' do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    log4j_cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.log4j_directives)
    log_file = '/opt/cassandra/conf/log4j-server.properties'
    Chef::Application.fatal!("Can't find the log file - #{log_file} ") if !File.exists? log_file
    merge_log4j_directives(log_file, log4j_cfg)
  end
  only_if { log4j_directive_supported? && ver <= 2.0}
end

if ver > 2.0
  cfg = {}
  if node.workorder.rfcCi.ciAttributes.has_key?("log4j_directives") 
    cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.log4j_directives)
  end
  node.default['log4j.rootLevel'] = 'INFO'
  log4j_attrs.each do |key,value|
    v = cfg.fetch(key,value)
    v.strip!
    if key.eql?('log4j.rootLogger')
      levels = log_levels & v.split(',')
      node.default['log4j.rootLevel'] = levels.first
      node.default[key] = v.upcase
    else
      node.default[key] = v
    end
  end
  
  template "/opt/cassandra/conf/logback.xml" do
    source "logback.xml.erb"
    owner "root"
    group "root"
    mode 0644
  end  
end