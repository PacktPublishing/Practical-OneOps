instance_id = node.workorder.rfcCi.ciName.split('-').last
if instance_id.to_i != 1
  Chef::Log.info("skipping non-primary instance")
  return
end

filename = "/tmp/#{node.workorder.rfcCi.ciName}.yaml"
content = node.workorder.rfcCi.ciAttributes.deployment_yaml
variables = JSON.parse(node.workorder.rfcCi.ciAttributes.variables)
variables.each_pair do |k,v|
  if v.include?('etcd')
    key = v.gsub('etcd:','')
    value = `etcdctl get #{key}`.strip  
  else
    value = v
  end
  Chef::Log.info("replacing: #{k} with #{value}")
  content.gsub!(k,value)    
end

File.open(filename, 'w') { |file| file.write(content) }

cmd = "kubectl delete -f #{filename}"
puts cmd
puts `#{cmd}`

sleep 5

cmd = "kubectl create -f #{filename}"
puts cmd
puts `#{cmd}`
