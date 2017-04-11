#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: datanode_start
#
#

# start datanode
ruby_block "Start hadoop-datanode service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hadoop-datanode start ",
            :live_stream => Chef::Log::logger)
    end
end
