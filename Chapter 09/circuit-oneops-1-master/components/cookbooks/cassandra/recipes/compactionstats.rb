#
# Cookbook Name:: cassandra
# Recipe:: compactionstats
#
# Copyright 2014, OneOps
#
# All rights reserved - Do Not Redistribute
execute "/opt/cassandra/bin/nodetool compactionstats"
