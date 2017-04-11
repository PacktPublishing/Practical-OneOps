#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: secondarynamenode_stop
#
#

# stop secondarynamenode
ruby_block "Stop hadoop-secondarynamenode service" do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service hadoop-secondarynamenode stop ",
            :live_stream => Chef::Log::logger)
    end
end
