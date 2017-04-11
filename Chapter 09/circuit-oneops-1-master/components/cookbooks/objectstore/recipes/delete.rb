cloud_name = node[:workorder][:cloud][:ciName]
cloud_type = node[:workorder][:services][:filestore][cloud_name][:ciClassName].split(".").last.downcase


case cloud_type
  when /swift/
    include_recipe "swift::delete_objectstore"
  end
