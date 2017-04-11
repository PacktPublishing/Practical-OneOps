Chef::Log.info('Windows volume add recipe')
storage = nil
device_maps = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep['ciClassName'] =~ /Storage/
    storage = dep
	device_maps = storage['ciAttributes']['device_map'].split(" ")
    break
  end
end
Chef::Log.info("Storage: #{storage}")

ps_script = "#{Chef::Config[:file_cache_path]}/cookbooks/os/files/windows/Run-Script.ps1"
ps_volume_script = "#{Chef::Config[:file_cache_path]}/cookbooks/Volume/files/add_disk.ps1"

mount_point =  node.workorder.rfcCi.ciAttributes[:mount_point]
reg_ex = /[e-z]|[E-Z]/
if (mount_point.nil? || mount_point.length > 1 || !reg_ex.match(mount_point))
  exit_with_error ("Invalid mount point for a windows drive: #{mount_point}")
end

#No DependsOn storage, assuming it's an ephemeral disk - add it exit
if storage.nil?
  Chef::Log.info("no DependsOn Storage - Assuming ephemeral storage")
  #Execute PS script to add ephemeral disk (set online, initialize, create partition and format volume)
  arg_list = "-Command \"& {#{ps_volume_script} -DriveLetter #{mount_point} }\" "
  cmd = "#{ps_script} -ExeFile 'powershell.exe' -ArgList '#{arg_list}' "

  Chef::Log.info("cmd:"+cmd)
  powershell_script "Add-Ephemeral-Storage" do
    code cmd
  end
  
  return
end


include_recipe "shared::set_provider"

cloud_name = node[:workorder][:cloud][:ciName]
token_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
provider = node[:iaas_provider]
storage_provider = provider
storage_provider = node[:storage_provider] if token_class =~ /rackspace|ibm/
instance_id = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["instance_id"]
compute = provider.servers.get(instance_id)
Chef::Log.info("instance_id: "+instance_id)


############################################
###         1. Attach storage            ###
############################################
#Azure storage treated differently
if storage_provider =~ /azure/
  include_recipe "azuredatadisk::attach"
else
  #iterating through all storage slices
  device_maps.each do |dev_vol|
    vol_id = dev_vol.split(":")[0]
    dev_id = dev_vol.split(":")[1]
    Chef::Log.info("vol_id: "+vol_id)
    Chef::Log.info("dev_id: "+dev_id)

	vol = nil
    vol = storage_provider.volumes.get vol_id

    Chef::Log.info("vol: "+ vol.inspect.gsub("\n"," ").gsub("<","").gsub(">","") )

    #Attempt to attach
	begin

      case token_class
        #ibm
		when /ibm/
          unless vol.attached?
		    compute.attach(vol.id)
          end
		#openstack
		when /openstack/
          if vol.status == 'available'
		    vol.attach instance_id, dev_id
          end
		#rackspace
		when /rackspace/
		  rackspace_dev_id = dev_id.gsub(/\d+/,"")
          is_attached = false
          compute.attachments.each do |a|
            is_attached = true if a.volume_id = vol.id
          end
          if !is_attached
            compute.attach_volume vol.id, rackspace_dev_id
          end

		#ec2
		when /ec2/
          vol.device = dev_id.gsub("xvd","sd")
          vol.server = compute

	  end #case token_class

	rescue Fog::Compute::AWS::Error=>e
      if e.message =~ /VolumeInUse/
        Chef::Log.info("already added")
      else
        exit_with_error(e.inspect)
      end
    end

	#Wait until storage is attached
	fin = false
    max_retry = 10
    retry_count = 0

	while !fin && retry_count<max_retry do
      fin = true
	  vol = nil
      vol_state = ''
      vol = storage_provider.volumes.get vol_id
      if token_class =~ /openstack/
        vol_state = vol.status
      else
        vol_state = vol.state
      end

      Chef::Log.info("Attempt: #{retry_count}, volume: #{vol_id}, state: #{vol_state}")

	  if vol_state.downcase !~ /attached|in-use/
        fin = false
        sleep 30
      end
        
	  retry_count +=1
    end #while !fin && retry_count<max_retry do

    if !fin
      exit_with_error("max retry count of "+max_retry_count.to_s+" hit, volume #{vol_id} is still not attached. Status: #{vol_state}")
    end

  end  #device_maps.each do |dev_vol|
end #if storage_provider =~ /azure/


############################################
###           2. Add volume              ###
############################################
#iterating through all storage slices
device_maps.each do |dev_vol|
  vol_id = dev_vol.split(":")[0]
  Chef::Log.info("vol_id: "+vol_id)
	
  vol = nil
  vol = storage_provider.volumes.get vol_id

  #Execute PS script to add persistent disk (set online, initialize, create partition and format volume)
  storage_size = vol.size
  arg_list = "-Command \"& {#{ps_volume_script} -DriveLetter #{mount_point} -vol_id #{vol_id} -storage_size #{storage_size} }\" "
  cmd = "#{ps_script} -ExeFile 'powershell.exe' -ArgList '#{arg_list}' "

  Chef::Log.info("cmd:"+cmd)
  powershell_script "Add-Persistent-Storage" do
    code cmd
  end

end #device_maps.each do |dev_vol|
