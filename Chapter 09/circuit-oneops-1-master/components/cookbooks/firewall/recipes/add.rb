# add computes to the firewall

cloud_name = node[:workorder][:cloud][:ciName]
Chef::Log.info("Cloud Name: #{cloud_name}")

# get the firewall provider from the firewall service
provider = node[:workorder][:services][:firewall][cloud_name][:ciClassName].gsub('cloud.service.','').downcase.split('.').last
Chef::Log.info("Cloud Provider: #{provider}")

case provider
when /panos/
  include_recipe 'firewall::add_'+provider
else
  Chef::Log.info("firewall add not implemented for provider: #{provider}")
end
