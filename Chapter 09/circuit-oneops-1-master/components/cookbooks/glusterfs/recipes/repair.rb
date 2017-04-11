# for repair attempt to restart the glusterd service and start the volume
service "glusterd" do
	supports :restart => true, :status => true
	action :restart
end

vol_name = node.workorder.payLoad.RealizedAs[0][:ciName]
ruby_block "volume start #{vol_name}" do
    block do
      sleep 5
      execute_command("gluster volume start #{vol_name}")
    end
    only_if "gluster volume info #{vol_name}"
    action :create
end 
