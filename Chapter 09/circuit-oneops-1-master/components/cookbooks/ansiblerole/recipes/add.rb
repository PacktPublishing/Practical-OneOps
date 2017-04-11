ansible_role_name = node.workorder.rfcCi.ciAttributes.ansible_role_name
ansible_role_version = node.workorder.rfcCi.ciAttributes.ansible_role_version
ansible_role_source = node.workorder.rfcCi.ciAttributes.ansible_role_source
ansible_role_playbook = node.workorder.rfcCi.ciAttributes.ansible_role_playbook

if ansible_role_name != '' && ansible_role_source == ''
  ansiblerole_galaxy "#{ansible_role_name}" do
    name ansible_role_name
    version ansible_role_version
    action :install
  end
else
  if ansible_role_source.eql?("")
    puts "***FAULT:FATAL=MissingRoleSource You must provide yml content format where role can be downloaded!"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  else
    ansible_role_filename = "#{Chef::Config['file_cache_path']}/role_#{node.workorder.rfcId}_#{node.workorder.deploymentId}_#{node.workorder.dpmtRecordId}.yml"

    file "#{ansible_role_filename}" do 
      content ansible_role_source
    end

    ansiblerole_galaxy "#{ansible_role_filename}" do
      action :install_file
    end
  end
end

ansible_playbook = "#{Chef::Config['file_cache_path']}/playbook_#{node.workorder.rfcId}_#{node.workorder.deploymentId}_#{node.workorder.dpmtRecordId}.yml"

file "#{ansible_playbook}" do
  content ansible_role_playbook
end

ansiblerole_galaxy "#{ansible_playbook}" do
  action :run
end 
