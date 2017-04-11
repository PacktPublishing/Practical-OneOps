#
# Cookbook Name:: jboss
# Recipe:: update
#

# usually the add is idempotent and put the new config values into a config template then restart
include_recipe "jboss::add"
