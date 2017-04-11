#node.workorder.rfcCi.ciName
install_dir = "/opt/oneops/#{node.workorder.payLoad.RealizedAs.first['ciName']}"
Chef::Log.info("Using installation directory #{install_dir}")

directory "#{install_dir}" do
  recursive true
  action :delete
end