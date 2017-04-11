#
# Cookbook Name:: hadoop-yarn-v1
# Recipe:: ssh
#
#

# import helper library
require File.expand_path("../yarn_helper.rb", __FILE__)

# get all shared attributes from the custom payload- this definition is in the yarn_helper library
cia = getCia()

# get all fqdns of all the computes in the same environment- definition lives in yarn_helper library
fqdns = getFqdns()

# deploys the global ssh client config
cookbook_file "/etc/ssh/ssh_config" do
    source "ssh_config"
    owner "root"
    group "root"
    mode '0644'
end

# deploys sshd config
cookbook_file "/etc/ssh/sshd_config" do
    source "sshd_config"
    owner "root"
    group "root"
    mode '0644'
    notifies :restart, 'service[sshd]', :delayed
end

# deploys shosts with the list of fqdns
template "/etc/ssh/shosts.equiv" do
    source "shosts.equiv.erb"
    owner "root"
    group "root"
    mode "0644"
    variables({ :fqdns => fqdns })
end

# this is required for root host-based auth
link "/root/.shosts" do
    to "/etc/ssh/shosts.equiv"
end

# join list of fqdns as a single space separated string
fqdns_joined = fqdns.join(" ")

# generate known_hosts file
bash "generate ssh_known_hosts" do
    user "root"
    cwd "/etc/ssh"
    code <<-EOF
        /usr/bin/ssh-keyscan #{fqdns_joined} > /etc/ssh/ssh_known_hosts
    EOF
end

# restart sshd to pick up changes
service "sshd" do
    action [:enable, :start]
    supports :restart => true, :reload => true
end
