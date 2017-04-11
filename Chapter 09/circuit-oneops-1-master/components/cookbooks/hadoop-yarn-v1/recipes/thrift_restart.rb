#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: thrift_restart
#
#

# restart thrift service
ruby_block "restart hive-metastore service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hive-metastore restart ",
            :live_stream => Chef::Log::logger)
    end
end
