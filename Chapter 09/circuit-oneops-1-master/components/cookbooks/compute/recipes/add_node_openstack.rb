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

require 'fog'
require 'json'

# set fog / excon timeouts to 5min
Excon.defaults[:read_timeout] = 300
Excon.defaults[:write_timeout] = 300

#
# supports openstack-v2 auth
#

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

conn = Fog::Compute.new({
  :provider => 'OpenStack',
  :openstack_api_key => compute_service[:password],
  :openstack_username => compute_service[:username],
  :openstack_tenant => compute_service[:tenant],
  :openstack_auth_url => compute_service[:endpoint]
})


rfcCi = node["workorder"]["rfcCi"]
nsPathParts = rfcCi["nsPath"].split("/")
customer_domain = node["customer_domain"]
owner = node.workorder.payLoad.Assembly[0].ciAttributes["owner"] || "na"
node.set["max_retry_count_add"] = 30
ostype = node.workorder.payLoad.os[0].ciAttributes["ostype"]
if compute_service.has_key?("initial_user") && !compute_service[:initial_user].empty?
  node.set["use_initial_user"] = true
  initial_user = compute_service[:initial_user]
  # put initial_user on the node for the following recipes
  node.set[:initial_user] = initial_user
end

if ostype =~ /windows*/
  circuit_dir = "/opt/oneops/inductor/circuit-oneops-1"
  user_data_file = "#{circuit_dir}/components/cookbooks/compute/files/default/user_data_script.ps1"
  user_data_script = File.read(user_data_file)
  Chef::Log.info("user_data_script => SET")
end

Chef::Log.debug("Initial USER: #{initial_user}")
Chef::Log.info("compute::add -- name: "+node.server_name+" domain: "+customer_domain+" provider: "+cloud_name)
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))


flavor = ""
image = ""
availability_zones = []
availability_zone = ""
manifest_ci = {}
scheduler_hints = {}
server = nil

ruby_block 'set flavor/image/availability_zone' do
  block do

    if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
      availability_zones = JSON.parse(compute_service[:availability_zones])
    end

    if availability_zones.size > 0
      case node.workorder.box.ciAttributes.availability
      when "redundant"
        instance_index = node.workorder.rfcCi.ciName.split("-").last.to_i + node.workorder.box.ciId
        index = instance_index % availability_zones.size
        availability_zone = availability_zones[index]
      else
        random_index = rand(availability_zones.size)
        availability_zone = availability_zones[random_index]
      end
    end

    manifest_ci = node.workorder.payLoad.RealizedAs[0]

    if manifest_ci["ciAttributes"].has_key?("required_availability_zone") &&
      !manifest_ci["ciAttributes"]["required_availability_zone"].empty?

      availability_zone = manifest_ci["ciAttributes"]["required_availability_zone"]
      Chef::Log.info("using required_availability_zone: #{availability_zone}")
    end

    if rfcCi['rfcAction'] != 'replace' && 
      !rfcCi['ciAttributes']['instance_id'].nil? && 
      !rfcCi['ciAttributes']['instance_id'].empty?      
        server = conn.servers.get(rfcCi['ciAttributes']['instance_id'])
    else
      conn.servers.all.each do |i|
        if i.name == node.server_name && i.os_ext_sts_task_state != "deleting" && i.state != "DELETED"
          server = i
          break
        end
      end
      puts "***RESULT:instance_id=#{server.id}" unless server.nil?
    end

    if server.nil?
      # size / flavor
      flavor = conn.flavors.get node.size_id
      Chef::Log.info("flavor: "+flavor.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))

      # image_id
      image = conn.images.get node.image_id
      Chef::Log.info("image: "+image.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))

      exit_with_error "Invalid compute size provided #{node.size_id} .. Please specify different Compute size." if flavor.nil?
      exit_with_error "Invalid compute image provided #{node.image_id} .. Please specify different OS type." if image.nil?

    elsif ["BUILD","ERROR"].include?(server.state)
      msg = "vm #{server.id} is stuck in #{server.state} state"
      if defined?(server.fault)
        msg = "vm state: #{server.state} " + "fault message: " + server.fault["message"] + " fault code: " + server.fault["code"].to_s if !server.fault.nil? && !server.fault.empty?
      end
      exit_with_error "#{msg}"
    else
      node.set[:existing_server] = true
    end

  end
end

# security groups
security_groups = []
ruby_block 'setup security groups' do
  block do

    secgroups = []
    if node[:workorder][:payLoad].has_key?("DependsOn") &&
      secgroups = node[:workorder][:payLoad][:DependsOn].select{ |ci| ci[:ciClassName] =~ /Secgroup/ }
    end

    secgroups.each do |sg|
      if sg[:rfcAction] != "delete"
        security_groups.push(sg[:ciAttributes][:group_id])
        Chef::Log.info("Server inspect :::" + server.inspect)
        #Skip the dynamic sg update for ndc/edc due to OpenStack incompatibility
        unless (server.nil? || server.state != "ACTIVE") || ((cloud_name.include? "ndc") || (cloud_name.include? "edc"))
          # add_security_group to the existing compute instance. works for update calls as well for existing security groups
          begin
            res = conn.add_security_group(server.id, sg[:ciAttributes][:group_name])
            Chef::Log.info("add secgroup response for sg: #{sg[:ciAttributes][:group_name]}: "+res.inspect)
          rescue Excon::Errors::Error =>e
             msg=""
             case e.response[:body]
             when /\"code\": \d{3}+/
              error_key=JSON.parse(e.response[:body]).keys[0]
              msg = JSON.parse(e.response[:body])[error_key]['message']
              exit_with_error "#{error_key} .. #{msg}"
             else
              msg = JSON.parse(e.response[:body])
              exit_with_error "#{msg}"
             end
          rescue Exception => ex
              msg = ex.message
              exit_with_error "#{msg}"
          end
        end
      end
    end

    # add default security group
    sg = conn.list_security_groups.body['security_groups'].select { |g| g['name'] == "default"}
    Chef::Log.info("sg: #{sg.inspect}")
    security_groups.push(sg.first["id"])

    Chef::Log.info("security_groups: #{security_groups.inspect}")

  end
end

mgmt_url = "https://"+node.mgmt_domain
mgmt_url = node.mgmt_url if node.has_key?("mgmt_url") && !node.mgmt_url.empty?

metadata = {
  "owner" => owner,
  "mgmt_url" =>  mgmt_url,
  "organization" => node.workorder.payLoad[:Organization][0][:ciName],
  "assembly" => node.workorder.payLoad[:Assembly][0][:ciName],
  "environment" => node.workorder.payLoad[:Environment][0][:ciName],
  "platform" => node.workorder.box.ciName,
  "component" => node.workorder.payLoad[:RealizedAs][0][:ciId].to_s,
  "instance" => node.workorder.rfcCi.ciId.to_s
}

ruby_block 'create server' do
  block do

    if server.nil?
      Chef::Log.info("server not found - creating")

      # openstack cant have .'s in key_pair name
      node.set["kp_name"] = node.kp_name.gsub(".","-")
      attempted_networks = []

      begin
        network_name, net_id = get_enabled_network(compute_service,attempted_networks)

        # network / quantum support
        if !net_id.empty?

          Chef::Log.info("metadata: "+metadata.inspect+ " key_name: #{node.kp_name}")

          server_request = {
            :name => node.server_name,
            :image_ref => image.id,
            :flavor_ref => flavor.id,
            :key_name => node.kp_name,
            :security_groups => security_groups,
            :metadata => metadata,
            :nics => [ { "net_id" => net_id } ]
          }

          Chef::Log.info("ostype: " + ostype)
          if ostype =~ /windows*/
            server_request[:user_data] = user_data_script
          end

          if !availability_zone.empty?
            server_request[:availability_zone] = availability_zone
          end

          if scheduler_hints.keys.size > 0
            server_request[:scheduler_hints] = scheduler_hints
          end

        else
          # older versions of openstack do not allow nics or security_groups
          server_request = {
            :name => node.server_name,
            :image_ref => image.id,
            :flavor_ref => flavor.id,
            :key_name => node.kp_name
          }
        end

        start_time = Time.now.to_i

        server = conn.servers.create server_request

        end_time = Time.now.to_i

        duration = end_time - start_time

        Chef::Log.info("server create returned in: #{duration}s")

        sleep 10
        server.reload
        sleep_count = 0

        # wait for server to be ready or fail within 5min
        while (!server.ready? && server.fault.nil? && sleep_count < 30) do
          sleep 10
          sleep_count += 1
          server.reload
        end

        if !server.fault.nil? && server.fault.has_key?('message')
          raise Exception.new(server.fault['message'])
        end        
        
        rescue Exception =>e
          message = ""
          case e.message
          when /Failed to allocate the network/
            Chef::Log.info("retrying different network due to: #{e.message}")
            attempted_networks.push(network_name)
            server.destroy
            sleep 5
            retry
                        
          when /Request Entity Too Large/,/Quota exceeded/
            limits = conn.get_limits.body["limits"]
            Chef::Log.info("limits: "+limits["absolute"].inspect)
            message = "openstack quota exceeded to spin up new computes on #{cloud_name} cloud for #{compute_service[:tenant]} tenant"
          else
            message = e.message
          end

          if e.respond_to?('response')
            case e.response[:body]
             when /\"code\": 400/
              message = JSON.parse(e.response[:body])['badRequest']['message']
            end
          end

          if message =~ /Invalid imageRef provided/
               Chef::Log.error(" #{node[:ostype]} OS type does not exist. Select the different OS type and retry the deployment")
               message = "Select the different OS type in compute component and retry the deployment"
          end

          if message =~ /availability zone/ && server_request.has_key?(:availability_zone)
            Chef::Log.info("availability zone: #{server_request[:availability_zone]}")
          end

          exit_with_error "#{message}"

      end

      end_time = Time.now.to_i
      duration = end_time - start_time
      Chef::Log.info("server ready in: #{duration}s")

    end

    puts "***RESULT:availability_zone=#{availability_zone}"
    Chef::Log.info("server: "+server.inspect.gsub("\n"," ").gsub("<","").gsub(">",""))
    puts "***RESULT:instance_id="+server.id
    hypervisor = server.os_ext_srv_attr_hypervisor_hostname || ""
    puts "***RESULT:hypervisor="+hypervisor
    puts "***RESULT:instance_state="+server.state
    task_state = server.os_ext_sts_task_state || ""
    puts "***RESULT:task_state="+task_state
    vm_state = server.os_ext_sts_vm_state || ""
    puts "***RESULT:vm_state="+server.os_ext_sts_vm_state
    puts "***RESULT:metadata="+JSON.dump(metadata)

  end
end

private_ip = ''
public_ip = ''

ruby_block 'set node network params' do
  block do
    if server.addresses.has_key? "public"
      public_ip = server.addresses["public"][0]["addr"]
      node.set[:ip] = public_ip
      puts "***RESULT:public_ip="+public_ip
      if ! server.addresses.has_key? "private"
        puts "***RESULT:dns_record="+public_ip
        # in some openstack installs only public_ip is set
        # lets set private_ip to this addr too for other cookbooks which use private_ip
        private_ip = public_ip
        puts "***RESULT:private_ip="+private_ip
      end
    end

    # use private ip if both are set
    if server.addresses.has_key? "private"
      private_ip = server.addresses["private"][0]["addr"]
      node.set[:ip] = private_ip
      puts "***RESULT:private_ip="+private_ip
      puts "***RESULT:dns_record="+private_ip
    end

    # enabled_networks
    if compute_service.has_key?('enabled_networks')
      JSON.parse(compute_service['enabled_networks']).each do |net|
        Chef::Log.info("checking for address by network name: #{net}")
        if server.addresses.has_key?(net)
          addrs = server.addresses[net]
          exit_with_error "multiple ips returned" if addrs.size > 1
          public_ip = addrs.first["addr"]
          private_ip = public_ip
          node.set[:ip] = public_ip
          break
        end
      end
    end
      
    # specific network
    if !compute_service[:subnet].empty?
      network_name = compute_service[:subnet]
      if server.addresses.has_key?(network_name)
        addrs = server.addresses[network_name]
        addrs_map = {}
        # some time openstack returns 2 of same addr
        addrs.each do |addr|
          next if ( addr.has_key? "OS-EXT-IPS:type" && addr["OS-EXT-IPS:type"] != "fixed" )
          ip = addr['addr']
          exit_with_error "The same ip #{ip} returned multiple times" if addrs_map.has_key? ip
          addrs_map[ip] = 1
        end
        private_ip = addrs.first["addr"]
        node.set[:ip] = private_ip
      end
    end

    if private_ip.empty?
      server.addresses.each_value do |addr_list|
        addr_list.each do |addr|
          puts "addr: #{addr.inspect}"
          if addr["OS-EXT-IPS:type"] == "fixed"
            private_ip = addr["addr"]
            node.set[:ip] = private_ip
          end
        end
      end
    end

    if((public_ip.nil? || public_ip.empty?) &&
       rfcCi["rfcAction"] != "add" && rfcCi["rfcAction"] != "replace")
      public_ip = node.workorder.rfcCi.ciAttributes.public_ip
      node.set[:ip] = public_ip
      Chef::Log.info("node ip: " + node.ip)
      Chef::Log.info("Fetching ip from workorder rfc for compute update")
    end

    if node.workorder.rfcCi.ciAttributes.require_public_ip == 'true' && public_ip.empty?
      if compute_service[:public_network_type] == "floatingip"
        server.addresses.each_value do |addr_list|
          addr_list.each do |addr|
            puts "addr: #{addr.inspect}"
            if addr["OS-EXT-IPS:type"] == "floating"
              public_ip = addr["addr"]
              node.set["ip"] = public_ip
            end
          end
        end
        if public_ip.empty?
          floating_ip = conn.addresses.create
          floating_ip.server = server
          public_ip = floating_ip.ip
        end
      end
    end
    private_ipv6 = ''
    server.addresses.each_value do |addr_list|
      addr_list.each do |addr|
        puts "addr: #{addr.inspect}"
        if addr["OS-EXT-IPS:type"] == "fixed" && addr["version"] == 6
          private_ipv6 = addr["addr"]
          Chef::Log.info("private ipv6 address:#{private_ipv6}")
        end
      end
    end

    puts "***RESULT:public_ip="+public_ip
    dns_record = public_ip
    if dns_record.empty? && !private_ip.empty?
      dns_record = private_ip
    end
    puts "***RESULT:dns_record="+dns_record
    # lets set private_ip to this addr too for other cookbooks which use private_ip
    puts "***RESULT:private_ip="+private_ip
    puts "***RESULT:host_id=#{server.host_id}"
    puts "***RESULT:private_ipv6="+private_ipv6

    if node.ip_attribute == "private_ip"
      node.set[:ip] = private_ip
      Chef::Log.info("setting node.ip: #{private_ip}")
    else
      node.set[:ip] = public_ip
      Chef::Log.info("setting node.ip: #{public_ip}")
    end

    if server.image.has_key? "id"
      server_image_id = server.image["id"]
      server_image = conn.images.get server_image_id
      if ! server_image.nil?
        puts "***RESULT:server_image_id=" + server_image_id
        puts "***RESULT:server_image_name=" + server_image.name
      end
    end
  end
end

ruby_block 'catch errors/faults' do
  block do
    # catch faults
    if !server.fault.nil? && !server.fault.empty?
      Chef::Log.error("server.fault: "+server.fault.inspect)
      exit_with_error "NoValidHost - #{cloud_name} openstack doesn't have resources to create your vm" if server.fault.inspect =~ /NoValidHost/
    end
    # catch other, e.g. stuck in BUILD state
    if !node.has_key?("ip") || node.ip.nil?
      msg = "server.state: "+ server.state + " and no ip for vm: #{server.id}"
      exit_with_error "#{msg}"
    end
    # catch other, e.g. VM is in ERROR state
    if "#{server.state}".eql? "ERROR"
      msg = "server.state: "+ server.state + "The newly spawned VM is in ERROR state"
      exit_with_error "#{msg}"
    end
  end
end

#give windows some time to initialize - 4 min
ruby_block 'wait for windows initialization' do
  block do
      sleep 60
  end
end if node[:ostype] =~ /windows/

include_recipe "compute::ssh_port_wait"

ruby_block 'handle ssh port closed' do
  block do
    if node[:ssh_port_closed]
      Chef::Log.error("ssh port closed after 5min, dumping console log")
      begin
        console_log = server.console.body
        console_log["output"].split("\n").each do |row|
          case row
          when /IP information for eth0... failed|Could not retrieve public key from instance metadata/
            puts "***FAULT:KNOWN=#{row}"
          else
            exit_with_error "SSH port not open on VM"
          end
          Chef::Log.info("console-log:" +row)
        end
      rescue Exception => e
        Chef::Log.error("could not dump console-log. exception: #{e.inspect}")
      end
      exit_with_error "ssh port closed after 5min"
    end
  end
end
