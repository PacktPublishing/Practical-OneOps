include_recipe "inductor::cloud"

execute "inductor enable #{node[:inductor_cloud]}" do
  cwd node[:inductor][:inductor_home]
end
