require 'securerandom'

username = node[:user][:username]
if node['platform'] =~ /windows/
  home_dir = "C:/Cygwin64/home/#{username}" 
  group_primary = 'Administrators'
else
  Chef::Log.info("Stopping the nslcd service")
  `sudo killall -9  /usr/sbin/nslcd`
  home_dir = node[:user][:home_directory]  
  group_primary = username
end

node.set[:user][:home] = home_dir && !home_dir.empty? ? home_dir : "/home/#{username}"

#Generate random password if needed
password = node[:user][:password]
if password.nil? || password.size == 0
  password = SecureRandom.urlsafe_base64(14)
end

user username do
  #Common attributes
  comment node[:user][:description]
  manage_home true
  home node[:user][:home]
  
  if node['platform'] =~ /windows/ 
    #Windows-specific attributes
    action :create
	password password
  else	
    #Non-Windows specific attributes
    if node[:user][:system_user] == 'true'
      system true
      shell '/bin/false'
    else
      shell node[:user][:login_shell] unless node[:user][:login_shell].empty?
    end
  
	if node['etc']['passwd'][username]
      action :modify
    else
      action :create
    end
  end #if node['platform'] =~ /windows/ 
end

#Manage group membership
groups = JSON.parse(node[:user][:group])
groups |= [group_primary]

groups.each do |g|
  group g do
    action :create
    members [username]
    if node['platform'] =~ /windows/ 
	  append true
	end
  end
end

#Home and .ssh directories
if node[:user].has_key?("home_directory_mode")
  home_mode = node[:user][:home_directory_mode]
else
  home_mode = 0700
end

directory "#{node[:user][:home]}" do
  owner username
  group group_primary
  mode home_mode
  if node['platform'] =~ /windows/
    rights :full_control, 'oneops'
	inherits false
  end
end

directory "#{node[:user][:home]}/.ssh" do
  owner username
  group group_primary
  mode 0700
  if node['platform'] =~ /windows/
    rights :full_control, 'oneops'
	inherits false
  end  
end

#SSH keys
file "#{node[:user][:home]}/.ssh/authorized_keys" do
  owner node[:user][:username]
  group group_primary
  mode 0600
  content JSON.parse(node[:user][:authorized_keys]).join("\n")
  if node['platform'] =~ /windows/
    rights :full_control, 'oneops'
	inherits false
  end
end

#The rest of attributes are Linux specific
return if node['platform'] =~ /windows/


if node[:user][:sudoer] == 'true'
  Chef::Log.info("adding #{username} to sudoers.d")
  `echo "#{username} ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers.d/#{username}`
  `chmod 440 /etc/sudoers.d/#{username}`
else
  `rm -f /etc/sudoers.d/#{username}`
end

# workaround for docker containers
docker = system 'test -f /.dockerinit'

if !docker
  ulimit = node[:user][:ulimit]
  if (!ulimit.nil?)
    Chef::Log.info("Setting ulimit to " + ulimit)
     `grep -E "^#{username} soft nofile" /etc/security/limits.conf`
     if $?.to_i == 0
      Chef::Log.info("ulimit already present for #{username} in the file /etc/security/limits.conf")
      `sed -i '/#{username}/d' /etc/security/limits.conf`
     end
      Chef::Log.info("adding ulimit for #{username}")
      `echo "#{username} soft nofile #{ulimit}" >> /etc/security/limits.conf`
      `echo "#{username} hard nofile #{ulimit}" >> /etc/security/limits.conf`

  else
  	Chef::Log.info("ulimit attribute not found. Not writing to the limits.conf")
  end
else
  Chef::Log.info("changing limits.conf not supported on containers")
end
