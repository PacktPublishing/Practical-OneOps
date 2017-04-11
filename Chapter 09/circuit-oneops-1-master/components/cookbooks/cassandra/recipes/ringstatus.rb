#
# Cookbook Name:: cassandra
# Recipe:: ringstatus
#
# Copyright 2014, OneOps
#
# All rights reserved - Do Not Redistribute
cmd = Mixlib::ShellOut.new("/opt/cassandra/bin/nodetool status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
