# status support doesn't work on ubuntu (returns 0 on server mysql status when its down), using pattern instead
service "mysql" do
  service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
  if (platform?("ubuntu") && node.platform_version.to_f >= 10.04)
    start_command "start mysql"
  end
  pattern "mysqld"
  supports :start => true
  action [ :start, :enable ]
end