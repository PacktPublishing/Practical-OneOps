def load_current_resource
  @timezone= new_resource.timezone_name
  @ntpserver_names = new_resource.ntpserver_names
end

action :set_time_zone do  
  set_timezone_script = "#{Chef::Config[:file_cache_path]}/cookbooks/windowsos/files/default/set-timezone.ps1"
  Chef::Log.error("set_timezone_script"+set_timezone_script)
  Chef::Log.error("timezone"+@timezone)
  cmd = "#{set_timezone_script} \"#{@timezone}\""
  Chef::Log.error("cmd:"+cmd)
  powershell_script "run set-timezone" do
    code cmd
  end   
end


action :set_ntpservers do
  Chef::Log.error("ntpservers:"+@ntpserver_names.inspect())
  ntpserver_value = "#{@ntpserver_names[0]},0x1 #{@ntpserver_names[1]},0x1"
  Chef::Log.error("ntpservers_value: "+ntpserver_value)
  registry_key "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\W32Time\\Parameters" do
     values [{
       :name => "NtpServer",
       :type => :string,
       :data => ntpserver_value
    }]
    action :create
  end
  
  service 'w32time' do
    supports status: true, restart: true
    action [:enable, :restart]
  end
end