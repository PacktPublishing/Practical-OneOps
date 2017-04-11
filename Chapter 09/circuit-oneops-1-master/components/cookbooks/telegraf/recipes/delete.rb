include_recipe "telegraf::stop"

name = node.workorder.payLoad.RealizedAs[0].ciName

initd_filename = 'telegraf'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else
  initd_filename = initd_filename + "_" + name
end

Chef::Log.info("checking " + initd_filename)
telegraf_init_filename = '/etc/init.d/#{initd_filename}'
Chef::Log.info("checking " + telegraf_init_filename)


ruby_block 'deleting #{initd_filename} ...' do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("rm -f #{telegraf_init_filename}",
        :live_stream => Chef::Log::logger)
    end
end

ruby_block 'deleting /etc/telegraf ...' do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("rm -rf /etc/telegraf",
        :live_stream => Chef::Log::logger)
    end
end

execute "chkconfig --del #{initd_filename}" do
  returns [0,9]
end
