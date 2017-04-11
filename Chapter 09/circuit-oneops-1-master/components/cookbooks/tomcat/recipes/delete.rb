tcat = tom_ver
tomcat_pkgs = value_for_platform(
  ["debian","ubuntu"] => {
    "default" => ["tomcat","tomcat-admin"]
  },
  ["centos","redhat","fedora"] => {
    "default" => ["tomcat","tomcat-admin-webapps"]
  },
  "default" => ["tomcat"]
)

service tom_ver do
  only_if { ::File.exists?("/etc/init.d/#{tcat}") }
  action [:stop, :disable]
end

tomcat_pkgs.each do |pkg|
  package pkg do
    action :purge
  end
end


case node["platform"]
when "centos","redhat","fedora"
  file "/etc/sysconfig/tomcat" do
    action :delete
  end
else
  file "/etc/default/tomcat" do
    action :delete
  end
end

directory "/etc/tomcat" do
  recursive true
  action :delete
end
