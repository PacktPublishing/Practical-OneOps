#
# Cookbook Name:: couchbase-cluster
# Recipe:: default
#
# Copyright 2015, Walmart
#
# All rights reserved - Do Not Redistribute
#
Chef::Log.info("base started")

user = ''
pass = ''
port = ''

@availability_mode = node.workorder.box.ciAttributes.availability
if @availability_mode == 'single'
  cb = node.workorder.payLoad.DependsOn.select { |cm| cm['ciClassName'].split('.').last == 'Couchbase'}.first
  cba = cb[:ciAttributes]
  user = cba['adminuser']
  pass = cba['adminpassword']
  port = cba['port']
else

  # dynamic payload defined in the pack to get the resources
  dependencies = node.workorder.payLoad.cm
  dependencies.each do |depends_on|
    class_name = depends_on["ciClassName"].downcase.gsub("bom\.oneops\.1\.","")
    Chef::Log.info("class_name:#{class_name}")
    if class_name == "couchbase"
      if depends_on["ciAttributes"].has_key?("adminuser")
        user = depends_on["ciAttributes"]["adminuser"]
      end

      if depends_on["ciAttributes"].has_key?("adminpassword")
        pass = depends_on["ciAttributes"]["adminpassword"]
      end

      if depends_on["ciAttributes"].has_key?("port")
        port = depends_on["ciAttributes"]["port"]
      end
    end
  end
end

node.set[:couchbase][:user] = user
node.set[:couchbase][:pass] = pass
node.set[:couchbase][:port] = port
