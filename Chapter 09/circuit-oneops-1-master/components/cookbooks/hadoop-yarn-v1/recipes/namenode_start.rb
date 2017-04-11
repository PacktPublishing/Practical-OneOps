#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: namenode_start
#
#

# start namenode
ruby_block "Start hadoop-namenode service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hadoop-namenode start ",
            :live_stream => Chef::Log::logger)
    end
end
