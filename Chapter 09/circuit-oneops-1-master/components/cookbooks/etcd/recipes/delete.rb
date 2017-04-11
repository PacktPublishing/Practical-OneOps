# Cookbook Name:: etcd
# Attributes:: delete
#
# Author : OneOps
# Apache License, Version 2.0

require 'net/http'
require 'uri'

extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

# Removing etcd member
member_id = node.workorder.rfcCi['ciAttributes']['member_id']

platform_level_fqdn = false
etcd_conn = "localhost"
# need to get cloud-level fqdn
etcd_conn = get_fqdn(node[:ipaddress], platform_level_fqdn) if depend_on_hostname_ptr?

# if VM is replaced, `member_id` will be empty, so another way
# to retrieve member_id is to query the etcd cluster
if member_id.nil? || member_id.empty?
  json_members = get_etcd_members_http(etcd_conn, 2379)
  Chef::Log.info("json_members: "+JSON.parse(json_members).inspect.gsub("\n"," "))

  members = JSON.parse(json_members)["members"]
  members.each do |m|
    if node.workorder.payLoad.ManagedVia[0]['ciName'] == m["name"]
      member_id = m["id"]
      break
    end
  end
  Chef::Log.info("d: #{member_id} from querying Etcd cluster")
end

# only delete the member if member_id is not empty
unless member_id.nil? || member_id.empty?
  uri = URI.parse("http://#{etcd_conn}:2379/v2/members/#{member_id}")
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Delete.new(uri.path)
  res = http.request(req)

  if res.code != '204'
    msg = "Failure deleting etcd member #{member_id}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
  else
    msg = "Success deleting etcd member #{member_id}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
    Chef::Log.info(msg)
  end
end

# stop etcd service.
service 'etcd' do
  action :stop
end

# remove etcd files
execute "rm -rf /tmp/etcd* #{node.etcd.working_location} #{node.etcd.conf_location} /usr/bin/etcd* #{node.etcd.systemd_file} #{node.etcd.extract_path} #{node.etcd.security_path}"
