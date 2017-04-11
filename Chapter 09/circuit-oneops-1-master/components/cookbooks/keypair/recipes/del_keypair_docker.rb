cloud_name = node[:workorder][:cloud][:ciName]
cloud = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
rfcCi = node[:workorder][:rfcCi]
nspath = rfcCi["nsPath"].split("/").delete_if {|x| x.empty? || x == "bom" }
image_org = nspath.shift
image_version = nspath.pop
image_name = nspath.join('-')

docker_home = File.expand_path(cloud[:path])
docker_project = [ docker_home, rfcCi["nsPath"] ].join('/')

image = "#{image_org}/#{image_name}:#{image_version}"
execute "remove image #{image}" do
  command "docker rmi #{image}"
  only_if "docker inspect #{image}"
end

directory "#{docker_project}" do
  recursive true
  action :delete
end
