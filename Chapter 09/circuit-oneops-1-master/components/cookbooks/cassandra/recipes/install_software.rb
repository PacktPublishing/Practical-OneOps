case node.platform
when "ubuntu"
  include_recipe "cassandra::add_debian"
when "redhat"
  include_recipe "cassandra::add_redhat"
when "centos"
  include_recipe "cassandra::add_redhat"
when "fedora"
  include_recipe "cassandra::add_redhat"
else
  Chef::Log.error("platform not supported yet")  
end