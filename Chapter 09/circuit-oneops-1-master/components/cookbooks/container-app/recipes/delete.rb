instance_id = node.workorder.rfcCi.ciName.split('-').last
if instance_id.to_i != 1
  Chef::Log.info("skipping non-primary instance")
  return
end

filename = "/tmp/#{node.workorder.rfcCi.ciName}.yaml"
content = node.workorder.rfcCi.ciAttributes.deployment_yaml
File.open(filename, 'w') { |file| file.write(content) }

cmd = "kubectl delete -f #{filename}"
puts cmd
puts `#{cmd}`
