#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: hiveserver2_restart
#
#

# restart hiveserver2 service
ruby_block "restart hive-hiveserver2 service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hive-hiveserver2 restart ",
            :live_stream => Chef::Log::logger)
    end
end
