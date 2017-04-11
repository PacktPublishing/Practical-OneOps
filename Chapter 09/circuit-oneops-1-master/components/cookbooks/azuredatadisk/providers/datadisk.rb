action :create do
    dd_manager = Datadisk.new(@new_resource.node)
    dd_manager.create
  end

action :destroy do   
    dd_manager = Datadisk.new(@new_resource.node)
    dd_manager.delete_datadisk    
  end

action :attach do
    dd_manager = Datadisk.new(@new_resource.node)
    dd_manager.attach
  end

action :detach do 
    dd_manager = Datadisk.new(@new_resource.node)
    dd_manager.detach
  end