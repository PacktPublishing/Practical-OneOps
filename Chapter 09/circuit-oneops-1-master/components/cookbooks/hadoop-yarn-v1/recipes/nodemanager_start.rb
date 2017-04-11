#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: nodemanager_start
#
#

# start nodemanager
ruby_block "Start hadoop-nodemanager service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hadoop-nodemanager start ",
            :live_stream => Chef::Log::logger)
    end
end
