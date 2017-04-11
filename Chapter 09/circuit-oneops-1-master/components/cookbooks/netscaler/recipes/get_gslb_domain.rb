# wmt:
# d1-pricing.glb.dev.walmart.com
# oo:
# env-assembly-platform.glb.dev.walmart.com
#

env_name = node.workorder.payLoad.Environment[0]["ciName"]
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
platform_name = node.workorder.box.ciName

cloud_name = node[:workorder][:cloud][:ciName]
gdns = node[:workorder][:services][:gdns][cloud_name][:ciAttributes]
base_domain = gdns[:gslb_base_domain]

if base_domain.nil? || base_domain.empty?
    msg = "#{cloud_name} gdns cloud service has empty gslb_base_domain"
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e  
end

node.set["gslb_base_domain"] = base_domain

# user selected composite of assmb, env, org
subdomain = node.workorder.payLoad.Environment[0]["ciAttributes"]["subdomain"]

gslb_domain = [platform_name, subdomain, base_domain].join(".")
if subdomain.empty?
  gslb_domain = [platform_name, base_domain].join(".")
end
node.set["gslb_domain"] = gslb_domain.downcase
