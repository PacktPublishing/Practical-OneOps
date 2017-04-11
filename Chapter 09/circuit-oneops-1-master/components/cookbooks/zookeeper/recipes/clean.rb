script "clean_up_data_dir" do
  interpreter "bash"
  user node[:zookeeper][:user]
  cwd  "#{node[:zookeeper][:install_dir]}/zookeeper-#{node[:zookeeper][:version]}/bin/"
  code <<-EOH
      ./zkCleanup.sh "#{node[:zookeeper][:autopurge_snapretaincount]}"
     EOH
end
