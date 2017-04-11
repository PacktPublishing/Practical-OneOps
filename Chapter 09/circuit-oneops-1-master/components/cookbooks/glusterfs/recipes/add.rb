
environment = node.workorder.payLoad.Environment[0][:ciAttributes][:availability]

exit_with_error "single environment. glusterfs setup works in redundant mode only" if environment=="single"

ci = node.workorder.rfcCi
parent = node.workorder.payLoad.RealizedAs[0]
replicas = ci.ciAttributes[:replicas].to_i
local_compute_index = ci[:ciName].split('-').last.to_i
local_cloud_index = ci[:ciName].split('-').reverse[1].to_i
computes = node.workorder.payLoad.RequiresComputes
compute_cinames=Array.new

computes.each do |c|
  compute_cinames.push("#{c.ciName}")
end
last_compute=compute_cinames.max

volstore_prefix = "#{ci.ciAttributes[:store]}/#{parent[:ciName]}"
Chef::Log.info("Distributed filesystem on #{computes.size.to_s} computes with #{replicas.to_s} data replicas")

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key? "mirror"
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
else
  exit_with_error "Cloud Mirror Service has not been defined"
end

glusterfs_source = mirrors['glusterfs']
if glusterfs_source.nil?
  exit_with_error "glusterfs source repository has not beed defined in cloud mirror service"
else
  Chef::Log.info("glusterfs source repository has been defined in cloud mirror service #{glusterfs_source}")
end

template "/etc/yum.repos.d/glusterfs.repo" do
  source "glusterfs.repo.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({
    :glusterfs_source => glusterfs_source,
    :glusterfs_version => node.glusterfs.version
  })
end

%w{glusterfs glusterfs-libs}.each do |p|
  package p do
    action :remove
  end
end

%w{attr psmisc lvm2}.each do |p|
  package p do
    action :install
  end
end

%w{glusterfs-client glusterfs-server glusterfs-common glusterfs-devel}.each do |p|
  bash "installing package #{p}" do
    code <<-EOH
      yum --assumeyes --disablerepo "*" --enablerepo "glusterfs" install #{p}
    EOH
  end
end

service "glusterd" do
  supports :restart => true, :status => true
  action [ :enable, :start ]
end

# staircase brick layout optimized for minimum migrations when computes are added
local_bricks = find_bricks(local_compute_index,replicas,computes.length)

local_bricks.each do |b|
  directory "#{volstore_prefix}/#{b}" do
    recursive true
  end
end

include_recipe "glusterfs::remote_probe"

ruby_block "glusterfs block" do
  block do

    if last_compute == "compute-#{local_cloud_index}-#{local_compute_index}"
      computes.each do |c|
        retry_count = 1
          while retry_count < 10
            command = "gluster peer probe #{c.ciAttributes[:private_ip]}"
            output = `#{command} 2>&1`
            if $?.success?
              Chef::Log.info("#{command} got successful. #{output}")
              break
            else
              Chef::Log.info("#{command} got failed. #{output}")
              Chef::Log.info("Maximum retry count is 9. Current retry count is #{retry_count}. Sleeping 20 seconds. ")
              sleep 20
            end
            exit_with_error "#{command} got failed. #{output}" if retry_count == 9
            retry_count += 1
          end
      end

      execute_command("gluster peer status")

      bricks = {}
      computes.each do |c|
        compute_bricks = find_bricks(c[:ciName].split('-').last.to_i,replicas,computes.length)
        Chef::Log.info("Bricks for #{c[:ciName]} (#{c.ciAttributes[:private_ip]}) #{compute_bricks.inspect}")
        compute_bricks.each do |b|
          bricks["#{c.ciName}"] = "#{c.ciAttributes[:private_ip]}:#{volstore_prefix}/#{b}"
        end
      end
      replicas_arg = replicas > 1 ? "replica #{replicas}" : ""
      bricks_arg = bricks.sort.map{|b| b[1]}.join(' ')

      `gluster volume info #{parent[:ciName]}`
      execute_command("yes y | gluster volume create #{parent[:ciName]} #{replicas_arg} #{bricks_arg} force")  if !$?.success?

      existing_bricks = `gluster volume info #{parent[:ciName]}`.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}.*/)
      new_bricks = bricks_arg.split(' ')
      existing_peers = extract_hosts_from_bricks(existing_bricks)
      new_peers = extract_hosts_from_bricks(new_bricks)

      scale = "none"
      scale, bricks = "up", (new_bricks - existing_bricks).join(' ') if existing_bricks.length < new_bricks.length
      scale, bricks, peers = "down", (existing_bricks - new_bricks).join(' '), existing_peers - new_peers if existing_bricks.length > new_bricks.length

      case scale
      when "up"
        Chef::Log.info("scaling up gluster volume #{parent[:ciName]} by adding brick(s) #{bricks}")
        execute_command("yes y | gluster volume add-brick #{parent[:ciName]} #{replicas_arg} #{bricks} force", false)
      when "down"
        Chef::Log.info("scaling down gluster volume #{parent[:ciName]} by removing brick(s) #{bricks}")
        execute_command("yes y | gluster volume remove-brick #{parent[:ciName]} #{replicas_arg} #{bricks} force", false)
        Chef::Log.info("scaling down gluster pool by detaching peer(s) #{peers.join(',')}")
        peers.each do |p|
          execute_command("gluster peer detach #{p} force", false)
        end
      end

      commands = ["yes y | gluster volume rebalance #{parent[:ciName]} fix-layout start",
       "sleep 5",
       "gluster volume start #{parent[:ciName]}",
       "gluster volume info #{parent[:ciName]}"]

      commands.shift if scale == "none"

      commands.each do |cmd|
        execute_command(cmd, false)
      end
    end

  end
end

include_recipe "glusterfs::mount"
