site_name = node.workorder.box.ciName
iis_web_site site_name do
  action [:delete]
end
