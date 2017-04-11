require 'hyperkit'

rfcCi = node[:workorder][:rfcCi]

cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

client_cert = "#{Chef::Config[:file_cache_path]}/client_#{rfcCi[:ciId]}.crt"
client_key = "#{Chef::Config[:file_cache_path]}/client_#{rfcCi[:ciId]}.key"
sshkey = "#{Chef::Config[:file_cache_path]}/sshkey_#{rfcCi[:ciId]}.pub"
setrootpass = "#{Chef::Config[:file_cache_path]}/rootpass_#{rfcCi[:ciId]}.sh"

file client_cert do
  mode 0644
  content cloud[:client_cert]
end

file client_key do
  mode 0644
  content cloud[:client_key]
end

file sshkey do
  mode 0644
  content node.workorder.payLoad.SecuredBy[0][:ciAttributes][:public]
end

file setrootpass do
  mode 0644
  content "echo 'root:`date +%s | sha256sum | base64 | head -c 32 ; echo`' | chpasswd"
end

lxd = Hyperkit::Client.new(
            api_endpoint: "https://designare.home:1443",
            client_cert: client_cert,
            client_key: client_key,
            verify_ssl: false
          )

ruby_block "create #{node[:server_name]}" do
  block do
    begin
      server = lxd.container(node[:server_name])
      Chef::Log.info("server already exists")
      Chef::Log.debug(server.inspect)
    rescue Exception => e
      if e.class.name == 'Hyperkit::NotFound'
        Chef::Log.info("create server")
        create = lxd.create_container(node[:server_name], alias: node[:image_id])
        Chef::Log.debug(create.inspect)
      else
        raise e.inspect
      end
    end
  end
end

ruby_block "get status #{node[:server_name]}" do
  block do
    server = lxd.container_state(node[:server_name])
    Chef::Log.info(server.inspect)
    if server[:status] == "Stopped"
      Chef::Log.info("starting server")
      start = lxd.start_container(node[:server_name])
      Chef::Log.info(start.inspect)
      sleep 15
      server = lxd.container_state(node[:server_name])
    end
    # ipv4 address from eth0
    inet = server[:network][:eth0][:addresses].select { |a| a[:family] == "inet" }.first
    Chef::Log.info("ip: "+inet[:address])
    node.set[:ip] = inet[:address]
    puts "***RESULT:private_ip="+inet[:address]
    puts "***RESULT:public_ip="+inet[:address]
    puts "***RESULT:dns_record="+inet[:address]
    puts "***RESULT:instance_id="+node[:server_name]
  end
end

ruby_block "push public sshkey" do
  block do
    lxd.execute_command(node[:server_name], "yum -y install openssh-server openssh-clients")
    lxd.execute_command(node[:server_name], "systemctl enable sshd")
    lxd.execute_command(node[:server_name], "systemctl start sshd")
    lxd.execute_command(node[:server_name], "mkdir -p -m 0700 /root/.ssh")
    lxd.push_file(sshkey, node[:server_name], '/root/.ssh/authorized_keys', uid: 0, gid: 0, mode: 0600)
    lxd.push_file(setrootpass, node[:server_name], '/bin/setrootpass.sh', uid: 0, gid: 0, mode: 0700)
    lxd.execute_command(node[:server_name], "/bin/setrootpass.sh")
  end
end
