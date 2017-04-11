unless node.workorder.payLoad.has_key? "SecuredBy"
    Chef::Log.error("unsupported, missing SecuredBy")
    return false
end

# create the /root/.ssh dir
directory "/root/.ssh" do
    owner "root"
    group "root"
    recursive true
    mode '0755'
    action :create
end

ssh_key_file = "/root/.ssh/id_dsa"

file ssh_key_file do
    content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
    mode 0600
end