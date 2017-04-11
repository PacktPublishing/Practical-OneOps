
template node[:swift][:homepath] + '/openrc' do
  source 'openrc.erb'
  mode 644
  action :create
end
