if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

if ci.ciAttributes.has_key?("prod_level_checks_enabled")
  node.default[:prod_level_checks_enabled] = ci.ciAttributes.prod_level_checks_enabled
  prod_level_checks_enabled = node[:prod_level_checks_enabled]
else
  Chef::Log.warn("No prod_level_checks_enabled attribute found.")
  return
end

Chef::Log.info("======= prod_level_checks_enabled enabled = #{prod_level_checks_enabled} =====")

if profile == 'prod'
  if !prod_level_checks_enabled.eql?("true")
    Chef::Log.error("production level cloud configuration is NOT enabled for PROD profile: ")
    Chef::Log.error("environment profile      : #{profile}")
    Chef::Log.error("prod_level_checks_enabled: #{prod_level_checks_enabled}")
    # msg = "Environment Profile = #{profile}, prod_level_checks_enabled = #{prod_level_checks_enabled}. "
    # msg += "production level cloud configuration is NOT enabled for PROD profile: "
    # raise "#{msg}"
    return
  else
    Chef::Log.info("production level cloud configuration is enabled for PROD profile, Validating the minimum number of clouds and computes recommended to run an production environment. ")
    Chef::Log.info("environment profile      : #{profile}")
    Chef::Log.info("prod_level_checks_enabled: #{prod_level_checks_enabled}")
  end
else
  Chef::Log.info("No production level check is required.")
  Chef::Log.info("environment profile      : #{profile}")
  Chef::Log.info("prod_level_checks_enabled: #{prod_level_checks_enabled}")
  return
end

nodes = node.workorder.payLoad.RequiresComputes

cloud_to_computes = Hash.new

nodes.each do |compute|
  cloud_index = compute[:ciName].split('-').reverse[1].to_s
  if (cloud_to_computes[cloud_index] == nil)
    cloud_to_computes[cloud_index] = Array.new
  else
    cloud_to_computes[cloud_index].push(compute[:ciName])
  end
end

Chef::Log.info("**** cloud_to_computes: #{cloud_to_computes.to_s}")


Chef::Log.info("**** min_clouds: #{node['zookeeper']['min_clouds']}")
Chef::Log.info("**** min_computes_per_cloud: #{node['zookeeper']['min_computes_per_cloud']}")
min_clouds = node['zookeeper']['min_clouds'].to_i
min_computes_per_cloud = node['zookeeper']['min_computes_per_cloud'].to_i

if (cloud_to_computes.size < min_clouds)
    msg = "env = #{profile}, clouds = #{cloud_to_computes.size}. "
    msg += "Your cluster must have a minimum of #{min_clouds} clouds as required by high availability. "
    msg += "Please add more clouds or configure \"production level checks\" in platform:zookeeper, resource:zookeeper"
    if (profile =~ /(?i)prod/)
        raise "#{msg}"
    else
        Chef::Log.warn("#{msg}")
    end
  else
    Chef::Log.info("Deployment has required minimum number of clouds.: #{cloud_to_computes.size}")
end
clouds_with_less_computes = cloud_to_computes.select {|k,v| v.length < min_computes_per_cloud}
if (clouds_with_less_computes.size > 0)
    msg = "env = #{profile}, number of clouds with less computes = #{clouds_with_less_computes.size}. "
    msg += "Some clouds do not have #{min_computes_per_cloud} computes as required by high availability. "
    msg += "Please add more computes to the clouds or configure \"production level checks\" in platform:Zookeeper, resource:zookeeper"
    if (profile =~ /(?i)prod/)
        raise "#{msg}"
    else
        Chef::Log.warn("#{msg}")
    end
  else
    Chef::Log.info("Deployment has required minimum number of Computes.: #{min_computes_per_cloud}")
end
