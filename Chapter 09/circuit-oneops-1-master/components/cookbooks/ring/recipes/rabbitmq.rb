nodes = node.workorder.payLoad.ManagedVia
depends_on = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Rabbitmq/ }

#chosen     = depends_on.first
#user       = chosen[:ciAttributes][:mongodbuser]
#group      = chosen[:ciAttributes][:mongodbgroup]
#apath      = chosen[:ciAttributes][:apppath]
#replport   = chosen[:ciAttributes][:port]

gem_package "ghost"

# dns_record used for fqdn
dns_record = ""
nodes.each do |n|
  if dns_record == ""
    dns_record = n[:ciAttributes][:dns_record]
  else
    dns_record += ","+n[:ciAttributes][:dns_record]
  end
end
puts "***RESULT:dns_record=#{dns_record}"


#nodes.select { |n| n[:ciAttributes][:private_ip] == node[:ipaddress] }.each do |find_clusnode1|
#  clusnode1 = find_clusnode1[:ciAttributes][:private_dns].split('.').first
#  nodes.reject { |n| n[:ciAttributes][:private_ip] == node[:ipaddress] }.each do |cluster_node|
#    
#    if cluster_node.has_key?(:rfcAction)
#      
#      case cluster_node[:rfcAction]
#      
#      when 'add'
#        execute "ghost add #{cluster_node[:ciAttributes][:private_dns].split('.').first} #{cluster_node[:ciAttributes][:private_ip]}" do
#          not_if "ghost list | grep #{cluster_node[:ciAttributes][:private_dns].split('.').first}"
#        end
#        execute "Stop rabbitmq app on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} stop_app"
#          action :run
#        end
#        execute "Reset rabbitmq config on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} reset"
#          action :run
#        end
#        execute "Configure disk cluster" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} cluster rabbit@#{clusnode1} rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first}"
#          action :run
#        end
#        execute "Start rabbitmq app on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} start_app"
#          action :run
#        end
#      
#      when 'delete'
#        execute "Stop rabbitmq app on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} stop_app"
#          action :run
#        end
#        execute "Reset rabbitmq config on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} reset"
#          action :run
#        end
#        execute "Start rabbitmq app on remote node" do
#          command "rabbitmqctl -n rabbit@#{cluster_node[:ciAttributes][:private_dns].split('.').first} start_app"
#          action :run
#        end
#        execute "ghost delete #{cluster_node[:ciAttributes][:private_dns].split('.').first}" do
#          only_if "ghost list | grep #{cluster_node[:ciAttributes][:private_dns].split('.').first}"
#        end
#      end
#      
#    end
#  end
##end
