# skip if running in a container
execute "echo 'cassandra  -  memlock  unlimited'> /etc/security/limits.d/cassandra.conf" do
  not_if "dmesg | grep 'Initializing cgroup'"
end

execute "echo 'cassandra  -  nofile  100000'   >> /etc/security/limits.d/cassandra.conf"
