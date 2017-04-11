#
# Cookbook Name:: os
# Recipe:: upgrade-os-package
#
require 'json'

args = ::JSON.parse(node.workorder.arglist)

package_name=args["package"]

if package_name.to_s.strip.length == 0
  Chef::Log.error("\"package\" parameter not specified")
  exit 1
end

if node.platform? "ubuntu"
  upgrade_cmd = "sudo apt-get -o Dpkg::Options::='--force-confnew' --force-yes -fuy dist-upgrade"
  cmd = "apt-get -y update; DEBIAN_FRONTEND=noninteractive #{upgrade_cmd}"
  execute cmd
else
  ruby_block "Upgrade OS package" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("yum -y update #{package_name}", :live_stream => Chef::Log::logger)
    end
  end
end
