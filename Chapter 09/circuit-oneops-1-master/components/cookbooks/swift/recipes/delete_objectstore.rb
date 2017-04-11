
template node[:swift][:homepath] + "/openrc" do
  source 'openrc.erb'
  mode 00600
  action :delete
end
