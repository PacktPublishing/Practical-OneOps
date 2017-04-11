# home_dir = "/home/#{u['id']}"
# 
# # fixes CHEF-1699
# ruby_block "reset group list" do
  # block do
    # Etc.endgrent
  # end
  # action :nothing
# end
# 
# user u['id'] do
  # uid u['uid']
  # gid u['gid']
  # shell u['shell']
  # comment u['comment']
  # supports :manage_home => true
  # home home_dir
  # notifies :create, "ruby_block[reset group list]", :immediately
# end
# 
# directory "#{home_dir}/.ssh" do
  # owner u['id']
  # group u['gid'] || u['id']
  # mode "0700"
# end
# 
# file "#{home_dir}/.ssh/authorized_keys" do
  # source "authorized_keys.erb"
  # owner u['id']
  # group u['gid'] || u['id']
  # mode 0600
  # content sshkeys.join('\n')
# end
# 
# group "sysadmin" do
  # gid 2300
  # members sysadmin_group
# end