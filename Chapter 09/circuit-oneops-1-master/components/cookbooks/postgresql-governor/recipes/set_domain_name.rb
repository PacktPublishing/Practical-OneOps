require 'json'

hostname = nil
node.workorder.payLoad[:DependsOn].each do |dep|
    if dep["ciClassName"] =~ /Fqdn/
        hostname = dep
        break
    end
end

Chef::Log.info("------------------------------------------------------")
Chef::Log.info("Hostname: "+hostname.inspect.gsub("\n"," "))
Chef::Log.info("------------------------------------------------------")


if hostname.nil?
    Chef::Log.error("no DependsOn Hostname - exit 1")
    exit 1
end

# hostname["ciAttributes"]["entries"] could be 'String', but in hash format. Such as,

# {"pgsql-238213-1-11025373.stg.test-pgsql.platform.prod.oneops.com":["10.65.228.226"],"pgsql-238213-1-11025373.stg.test-pgsql.platform.daliaas4.prod.oneops.com":["10.65.228.226”]}

Chef::Log.info("ciBaseAttributes content: "+hostname["ciBaseAttributes"].inspect.gsub("\n"," "))
Chef::Log.info("ciAttributes content: "+hostname["ciAttributes"].inspect.gsub("\n"," "))

# so convert hostname["ciAttributes"]["entries"] into hash format by JSON,parse()
if !hostname["ciBaseAttributes"]["entries"].nil? && !hostname["ciBaseAttributes"]["entries"].empty?
  hash = JSON.parse(hostname["ciBaseAttributes"]["entries"])
  Chef::Log.info("use ciBaseAttributes")
else
  hash = JSON.parse(hostname["ciAttributes"]["entries"])
  Chef::Log.info("use ciAttributes")
end

# handle some corner cases, such as CNAME Alias
require 'resolv'
hash.delete_if {|key, value| key =~ Resolv::IPv4::Regex}
hash.delete_if {|key, value| value.is_a?(String)}

# hostnames are stored in key part of the hash
arr = hash.keys

# there could be 2 types of hostnames: (1) platform-level hostname, (2) cloud-level hostname.

# platform-level hostname always comes shorter in string length, so sort based on the string length and retrieve the shortest hostname, which is the platform-level hostname

platform_hostname = arr.sort_by{|s| s.length }[0]
Chef::Log.info("platform_hostname: " +  platform_hostname)

# remove the short hostname, such as "pgsql-4354455-1-72071278" from "pgsql-4354455-1-72071278.stg.test-pgsql.platform.prod.oneops.com".
# 'arr' will be something like "[stg, test-pgsql, platform, prod, oneops, com]"
arr = platform_hostname.split(".")[1..-1]

# join elements in arr with "." to get the domain name, prefix with platform name. Overall it should be the FQDN
platform_name = node.workorder.box.ciName
node.set[:platform_fqdn] = platform_name + "." + arr.join(".")

Chef::Log.info("Platform-level FQDN: "+ node[:platform_fqdn])
