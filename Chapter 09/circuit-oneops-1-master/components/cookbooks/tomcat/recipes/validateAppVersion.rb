#
# Cookbook Name:: tomcat
# Recipe:: versioncheck

include_recipe 'tomcat::versionstatus'
script="#{node[:versioncheckscript]}"

bash "CHECK_APP_VERSION" do
        code <<-EOH
          #{script}
          exit "$RETVAL"
        EOH
end
