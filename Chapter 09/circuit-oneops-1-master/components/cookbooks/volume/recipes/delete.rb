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

# volume::delete
#
# unmounts, removes: raid, lv vg and detaches blockstorage
#
is_windows = false
is_windows = true if node[:platform] =~ /windows/
Chef::Log.info("Is platform windows?: #{is_windows}")
has_mounted = false
cloud_name = node[:workorder][:cloud][:ciName]
provider_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
Chef::Log.info("provider: #{provider_class}")
rfcAttrs = node.workorder.rfcCi.ciAttributes
platform_name = node.workorder.box.ciName
Chef::Log.info("platform_name: #{platform_name}")

if rfcAttrs.has_key?("mount_point") && !rfcAttrs["mount_point"].empty?

  mount_point = rfcAttrs["mount_point"].gsub(/\/$/,"")
  Chef::Log.info("umount directory is: #{mount_point}")

  if !is_windows

    `grep #{mount_point} /etc/mtab`
    has_mounted = true if $? == 0

    case node[:platform]
    when "centos","redhat","fedora","suse"
      package "lsof"
    end

    ruby_block "killing open files at #{mount_point}" do
      block do
        `lsof #{mount_point} | awk '{print $2}' | grep -v PID | uniq | xargs kill -9`
      end
      only_if { has_mounted }
    end

    execute "umount -f #{mount_point}" do
      only_if { has_mounted }
    end

    # clear the tmpfs ramdisk entries and/or volume entries from /etc/fstab
    if(rfcAttrs["fstype"] == "tmpfs") || provider_class =~ /azure/ || provider_class =~ /cinder/
      Chef::Log.info("clearing /etc/fstab entry for fstype tmpfs")
      `grep -v #{mount_point} /etc/fstab > /tmp/fstab`
      `mv /tmp/fstab /etc/fstab`
      logical_name = node.workorder.rfcCi.ciName
      `rm -rf '/opt/oneops/azure-restore-ephemeral-mntpts/#{logical_name}.sh'`
      `cp /etc/rc.local tmpfile;sed -e "/\\/opt\\/oneops\\/azure-restore-ephemeral-mntpts\\/#{logical_name}.sh/d" tmpfile > /etc/rc.local;rm -rf tmpfile`
    end
  else
    ps_volume_script = "#{Chef::Config[:file_cache_path]}/cookbooks/Volume/files/del_disk.ps1"
    cmd = "#{ps_volume_script} \"#{mount_point}\""
    Chef::Log.info("cmd:"+cmd)

	powershell_script "Remove-Windows-Volume" do
      code cmd
    end
  end #if node.platform !~ /windows/
end

ruby_block 'lvremove ephemeral' do
  block do  
    if ::File.exists?("/dev/#{platform_name}-eph/#{node.workorder.rfcCi.ciName}")
      `lvremove -f #{platform_name}-eph/#{node.workorder.rfcCi.ciName}`
      execute_command("sudo rm -rf #{mount_point}")
    end
   end
end unless is_windows

supported = true
if provider_class =~ /virtualbox|vagrant|docker/
  Chef::Log.info(" virtual box vagrant and docker don't support iscsi/ebs via api yet - skipping")
  supported = false
end

storage = nil
if node.workorder.payLoad.has_key?('DependsOn')
  node.workorder.payLoad.DependsOn.each do |dep|
    if dep["ciClassName"] =~ /Storage/
      storage = dep
      break
    end
  end
end

if storage.nil?
  Chef::Log.info("no DependsOn Storage.")
  return
end

include_recipe "shared::set_provider"

ruby_block 'lvremove storage' do
  block do

    max_retry_count = 3

	if !is_windows
	  `lvremove -f #{platform_name}`
      
      raid_device = "/dev/md/"+ node.workorder.rfcCi.ciName
      retry_count = 0

      if provider_class =~ /rackspace/
        Chef::Log.info "no raid for rackspace"
      else
        while retry_count < max_retry_count && ::File.exists?(raid_device) do
          `mdadm --stop #{raid_device}`
          `mdadm --remove #{raid_device}`
          retry_count += 1
          if ::File.exists?(raid_device)
            Chef::Log.info("waiting 10sec for raid array to stop/remove")
            sleep 10
          end
        end
        if ::File.exists?(raid_device)
          exit_with_error "raid device still exists after many mdadm --stop #{raid_device}"
        end
      end
    end #if !is_windows

    provider = node.iaas_provider
    storage_provider = node.storage_provider
    instance_id = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_id"]
    Chef::Log.info("instance_id: "+instance_id)
    device_maps = storage['ciAttributes']['device_map'].split(" ")

      change_count = 1
      retry_count = 0
      while change_count > 0 && retry_count < max_retry_count
        change_count = 0    
     
        device_maps.each do |dev_vol|
          vol_id = dev_vol.split(":")[0]
          dev_id = dev_vol.split(":")[1]
          Chef::Log.info("vol: "+vol_id)

		  if provider_class =~ /rackspace|ibm/
            volume = storage_provider.volumes.get vol_id
          elsif provider_class =~ /azure/ && !is_windows
			Chef::Log.info("running: lvdisplay /dev/#{platform_name}/* ...")
            out=`lvdisplay /dev/#{platform_name}/*`
            Chef::Log.info("out: #{out}")
            if $? != 0 #No more volumes, disk can be detached.
              Chef::Log.info("There is no more volumes on the disk, so disk can be detached.")
              dd_manager = Datadisk.new(node) # using azuredatadisk library to detach, recipes cannot be called from the ruby block
              dd_manager.detach()
            end              
		  elsif provider_class =~ /azure/ && is_windows
		    Chef::Log.info("Windows: Assuming all volumes have been set offline.")
            dd_manager = Datadisk.new(node) # using azuredatadisk library to detach, recipes cannot be called from the ruby block
            dd_manager.detach()
          else
            volume = provider.volumes.get  vol_id
          end

          Chef::Log.info( "volume:"+volume.inspect.gsub("\n",""))

          begin
            if provider_class =~ /openstack/
              vol_state = volume.status.downcase
            elsif provider_class =~ /azure/
              Chef::Log.info("azuredatadisk no action needed")
            else
              vol_state = volume.state.downcase
            end
            
            if vol_state != "available" && vol_state != "detached"
              if vol_state != "detaching"
                Chef::Log.info("detaching "+vol_id)
                
                case provider_class
                when /openstack/
                  attached_instance_id = ""
                  if volume.attachments.size >0
                     attached_instance_id = volume.attachments[0]["serverId"]
                  end
                  
                  if attached_instance_id != instance_id
                     Chef::Log.info("attached_instance_id: #{attached_instance_id} doesn't match this instance_id: "+instance_id)
                  else
                    volume.detach instance_id, vol_id
                    sleep 10
                    detached=false
                    detach_wait_count=0

					while !detached && detach_wait_count<max_retry_count do
                      volume = provider.volumes.get vol_id
                      Chef::Log.info("vol state: "+volume.status)
                      if volume.status == "available"
                        detached=true
                      else
                        sleep 10
                        detach_wait_count += 1
                      end
                    end

					#Could not detach in allocated number of tries
					exit_with_error("Could not detach volume #{vol_id}") unless detached

                  end

                when /rackspace/
    	            compute = provider.servers.get instance_id
                  compute.attachments.each do |a|
                     Chef::Log.info "destroying: "+a.inspect
                     a.destroy
                  end
                when /ibm/
                  compute = provider.servers.get instance_id
                  compute.detach(volume.id)
                when /azure/
                   Chef::Log.info("azuredatadisk no action needed")
                else
                  # aws uses server_id
                  if volume.server_id == instance_id
                    volume.server = nil
                  else
                     Chef::Log.info("attached_instance_id: #{volume.server_id} doesn't match this instance_id: "+instance_id)
                  end
                end
    
              end
              change_count += 1
            else
              Chef::Log.info( "volume available.")
            end
          rescue  => e
            exit_with_error("#{e.message}" +"\n"+ "#{e.backtrace.inspect}")
          end
        end
    
        Chef::Log.info("this pass detach count: #{change_count}")
        if change_count > 0
          retry_sec = retry_count*10
          Chef::Log.info( "sleeping "+retry_sec.to_s+" sec...")
          sleep(retry_sec)
        end
        retry_count += 1
      end

  end
end
