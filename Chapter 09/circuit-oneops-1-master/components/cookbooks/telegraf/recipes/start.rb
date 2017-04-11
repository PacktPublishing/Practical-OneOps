#execute "Start telegraf server" do
#  command "/app/usr/bin/telegraf -config /app/etc/telegraf/telegraf.conf &"
#end


#name = node['telegraf']['name']
name = node.workorder.payLoad.RealizedAs[0].ciName
initd_filename = 'telegraf'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else
  initd_filename = initd_filename + "_" + name
end



ruby_block "start telegraf" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service #{initd_filename} start",
        :live_stream => Chef::Log::logger)
    end
end
