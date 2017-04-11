
require 'net/http'
require 'uri'

extend Etcd::Util
Chef::Resource::RubyBlock.send(:include, Etcd::Util)

# https://coreos.com/etcd/docs/latest/runtime-configuration.html#add-a-new-member
# need to add the member to the cluster first

platform_level_fqdn = false
etcd_conn = "localhost"

# need to get cloud-level fqdn which will be used as the URL to connect to
# etcd in the primary or secondary cloud
etcd_conn = get_fqdn(node[:ipaddress], platform_level_fqdn) if depend_on_hostname_ptr?

# no diff to use use platform-level or cloud-level hostname
full_hostname = get_full_hostname(node[:ipaddress])
peerURLs = "http://#{full_hostname}:2380"

uri = URI.parse("http://#{etcd_conn}:2379/v2/members")
req = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
req.body = "{\"peerURLs\":[\"#{peerURLs}\"]}"
http = Net::HTTP.new(uri.host, uri.port)

res = http.request(req)

if res.code != '201'
    msg = "Failure registering etcd member #{node[:ipaddress]}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL= #{msg}"
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
    else
    msg = "Success registering etcd member #{node[:ipaddress]}. response code: #{res.code}, response body #{res.body}, response message #{res.message}"
    Chef::Log.info(msg)
end