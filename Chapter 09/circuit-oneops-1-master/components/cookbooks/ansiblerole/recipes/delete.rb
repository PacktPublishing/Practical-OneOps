#
#
# In Ansible there isn't much of a rollback concept.
# Since this is a wrapper around Ansible's role unless
# it's provided otherwise we assume just removing the role
# from the box is sufficient.
#
#

role_name = node.workorder.rfcCi.ciAttributes.ansible_role_name
role_version = node.workorder.rfcCi.ciAttributes.ansible_role_version

ansiblerole_galaxy "#{role_name}" do
	name role_name
	version role_version
	action :remove
end