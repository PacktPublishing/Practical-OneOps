include_recipe "inductor::cloud"

execute "inductor restart #{node[:inductor_cloud]}" do
  cwd node[:inductor][:inductor_home]
end
