
# Set some metadata that's not available while in this
# procedure mode 

node.set["workorder"]["rfcCi"]["ciAttributes"]["hosts"] = "{}"
node.set["workorder"]["rfcCi"]["ciName"]  = node.workorder.ci.ciName
node.set["workorder"]["rfcCi"]["ciId"] = node.workorder.ci.ciId
node.set["workorder"]["rfcCi"]["ciAttributes"]["additional_search_domains"] = node.workorder.ci.ciAttributes.additional_search_domains
node.set["workorder"]["rfcCi"]["ciAttributes"]["dhclient"] = node.workorder.ci.ciAttributes.dhclient
node.set["vmhostname"] = node.workorder.box.ciName+'-'+node.workorder.cloud.ciId.to_s+'-'+node.workorder.ci.ciName.split('-').last.to_i.to_s+'-'+ node.workorder.ci.ciId.to_s
node.set["full_hostname"] = node["vmhostname"]+'.'+node["customer_domain"]

dhclient_cmdline = "/sbin/dhclient"

ruby_block "dhclient cleanup and reconfigure" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    dhclient_out = shell_out("ps auxwww|grep -v grep|grep dhclient")
    if dhclient_out.stdout =~ /.*:\d{2} (.*dhclient.*)/
      dhclient_cmdline = $1
      Chef::Log.info("DHCLIENT = #{dhclient_cmdline}")
    end

    pkill_out = shell_out("pkill -f dhclient")
    remove_cmd = shell_out("rm -rf /etc/dhcp/dhclient.conf")
    dhclient_start = shell_out(dhclient_cmdline)

    Chef::Log.info("dhclient start = #{dhclient_start.stdout}")

    if node["workorder"]["rfcCi"]["ciAttributes"]["dhclient"] != 'true'
      pkill_out = shell_out("pkill -f dhclient")
    end
  end
end

# run the network script
include_recipe "os::network"
