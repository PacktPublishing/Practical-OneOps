# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# rackspace::add_lb
#


include_recipe "rackspace::get_lb_service"

#computes = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Compute/ }
computes = node[:lb_members]
certs = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Certificate/ }
ecv_map = JSON.parse(node.workorder.rfcCi.ciAttributes.ecv_map)

Chef::Log.debug("COMPUTES: #{computes}")

node.loadbalancers.each do |lb_def|

  Chef::Log.info("lb name: "+lb_def[:name])

  conn = node[:rackspace_lb_service]
  lbs = conn.load_balancers.all.select{| clb| clb.name == lb_def[:name] }

  if lbs.length >0
   lb = lbs.first
  end

  nodes = []
  computes.each do |compute|
    nodes.push({
      :address => compute[:ciAttributes][:private_ip],
      :condition => "ENABLED",
      :port => lb_def[:iport]
    })
  end


  if lb.nil?
    Chef::Log.info("creating lb")

    # lb = conn.load_balancers.first
    lb = conn.load_balancers.create(
      :name => lb_def[:name],
      :port => lb_def[:vport],
      :protocol => lb_def[:iprotocol].upcase,
      :virtual_ips => [{:type => 'PUBLIC'}],
      :nodes => nodes
    )
    lb.wait_for { ready? }
  end

  Chef::Log.info("lb: #{lb.inspect}")

  nodes.each do |n|
    begin
      lb.nodes.create n
    rescue Fog::Rackspace::LoadBalancers::ServiceError => e
      if e.message !~ /Duplicate/
        raise e
      end
    end
  end

  if (node.lb.stickiness == "true" &&
     lb.session_persistence.nil? ) ||
     (node.lb.stickiness == "false" &&
     !lb.session_persistence.nil? )

    if node.lb.stickiness == "true"
      lb.enable_session_persistence("HTTP_COOKIE")
      Chef::Log.info("enable persistence")
    else
      begin
        lb.disable_session_persistence
        Chef::Log.info("disable persistence")
      rescue Fog::Rackspace::LoadBalancers::BadRequest => e
        Chef::Log.info("lb.session_persistence: "+lb.session_persistence.inspect)
      end

    end
    lb.wait_for { ready? }
  else
    Chef::Log.info("persistence ok")
  end


  ecv_map.keys.each do |port|
    next if port.to_i != lb_def[:iport].to_i
    options = {
      :path => ecv_map[port].gsub("GET ",""),
      :status_regex => "^[234][0-9][0-9]$"
    }

    lb.enable_health_monitor(
      lb_def[:iprotocol].upcase, # type
      10,     # interval
      5,      # timeout
      2,      # attempts
      options
    )
  end

  Chef::Log.info( "health_monitor: "+lb.health_monitor.inspect.gsub("\n","") )
  Chef::Log.info( lb.inspect.gsub("<","").gsub(">","").gsub("\n","") )
  Chef::Log.info( lb.virtual_ips.inspect.gsub("<","").gsub(">","").gsub("\n","") )
  Chef::Log.info( lb.nodes.inspect.gsub("<","").gsub(">","").gsub("\n","") )
  Chef::Log.info( "session_persistence: "+lb.session_persistence.inspect.gsub("\n","") )
  node.set[:virtual_ip] = lb.virtual_ips.first.address


  if certs.nil? || certs.size==0
    Chef::Log.info("no certs in DependsOn payload")
    begin
      lb.disable_ssl_termination()
    rescue Fog::Rackspace::LoadBalancers::BadRequest => e
      Chef::Log.info("not ssl terminated")
    end
    next
  end

  cert = certs.first
  options = {:enabled=> true}
  if cert[:ciAttributes].has_key?("cacertkey")
    options[:intermediate_certificate] = cert[:ciAttributes][:cacertkey]
  end

  Chef::Log.info("ssl_termination using key and cert")

  vservices = lb.ssl_termination

  Chef::Log.info("vservices:"+vservices.inspect)

  lb.enable_ssl_termination(
    443,
    cert[:ciAttributes][:key],
    cert[:ciAttributes][:cert],
    options
  )
end
