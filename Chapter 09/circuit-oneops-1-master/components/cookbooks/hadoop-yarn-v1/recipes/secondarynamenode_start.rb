#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: secondarynamenode_start
#
#

# start secondarynamenode
ruby_block "Start hadoop-secondarynamenode service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hadoop-secondarynamenode start ",
            :live_stream => Chef::Log::logger)
    end
end
