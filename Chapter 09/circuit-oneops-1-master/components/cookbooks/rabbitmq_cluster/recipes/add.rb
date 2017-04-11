
include_recipe "rabbitmq_cluster::default"

include_recipe "rabbitmq_cluster::join"

directory "/tmp/ssh" do
	recursive true
	action :delete
end
