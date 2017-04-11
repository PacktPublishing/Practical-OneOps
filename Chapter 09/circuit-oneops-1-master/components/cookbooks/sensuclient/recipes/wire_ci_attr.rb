#
# Cookbook Name:: Sensuclient
# Recipe:: wire_ci_attr
#
# Copyright 2016, kaushiksriram100@gmail.com
#
#
#

#get all component attributes

pack_name = node.workorder.box.ciAttributes['pack']
oneops_nspath = node.workorder.rfcCi.nsPath
nsPathParts = node.workorder.rfcCi.nsPath.split("/")
cloud = node[:workorder][:cloud][:ciName] 

#sensu_subscription = "#{nsPathParts[2]}-#{nsPathParts[5]}-#{nsPathParts[3]}"
#sensu_subscription = "#{pack_name}"
sensu_application = "#{cloud}.#{nsPathParts[2]}.#{nsPathParts[5]}-#{nsPathParts[3]}"
sensu_handlers = "default"
sensu_team_owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "na"


#node.set[:sensu][:subscription] = sensu_subscription
node.set[:sensu][:application] = sensu_application
node.set[:sensu][:handler] = sensu_handlers
node.set[:sensu][:team_owner] = sensu_team_owner
node.set[:sensu][:nspath] = oneops_nspath
