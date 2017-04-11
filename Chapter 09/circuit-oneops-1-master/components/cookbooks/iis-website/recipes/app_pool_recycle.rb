platform_name = node.workorder.box.ciName

iis_app_pool platform_name do
  action :recycle
end
