# status support doesn't work on ubuntu (returns 0 on server mysql status when its down), using pattern instead
# removed use of upstart for ubuntu due to redundant using the ocf script
service "mysql" do
  service_name value_for_platform([ "centos", "redhat", "suse", "fedora" ] => {"default" => "mysqld"}, "default" => "mysql")
  pattern "mysqld"
  action [ :stop, :disable ]
end