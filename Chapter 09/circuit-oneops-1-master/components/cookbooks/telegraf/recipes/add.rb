include_recipe "telegraf::pkg_install"
include_recipe "telegraf::setup"

Chef::Log.info("DEBUG-" + node['telegraf']['enable_test'])
configdir = node['telegraf']['configdir']
name = node.workorder.payLoad.RealizedAs[0].ciName
if node['telegraf']['enable_test'] == 'true'
  Chef::Log.info("DEBUG- Running Test")
  execute "Running test" do
    command "/usr/bin/telegraf -config #{configdir}/#{name}.conf -test"
  end
end


enable = node['telegraf']['enable_agent']
Chef::Log.info("DEBUG-enable=" + enable)
if node['telegraf']['enable_agent'] == 'true'
  Chef::Log.info("DEBUG-starting...")
  include_recipe "telegraf::start"
end
