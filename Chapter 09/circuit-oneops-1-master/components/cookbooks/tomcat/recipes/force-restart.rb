#
# Cookbook Name:: tomcat
# Recipe:: restart

include_recipe 'tomcat::force-stop'

include_recipe 'tomcat::start'

