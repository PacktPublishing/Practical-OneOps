if node[:php][:install_type]
  Chef::Log.info("Installation type #{node[:php][:install_type]} - running recipe php::#{node[:php][:install_type]}")
  include_recipe "php::#{node[:php][:install_type]}"
else
  Chef::Log.info("Installation type not specified - running default recipe php::repository")
  include_recipe "php::repository"
end
