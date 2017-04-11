This pack is naive way of incorporating Ansible into OneOps and is not the only way to do so.  It allows one to bootstrap Ansible and incorporate Role concept as well as any ad-hoc tasks in Ansible. 

Component:

`ansible` : This component sole purpose is to install and configure Ansible on the host machine. It has only one required attribute 'version'.  The component will install the version of Ansible according to this attribute.  Current implementation used Python's pip to install Ansible.  Make sure your system has access to PyPi to retrieve Ansible package.  Future enhancement may included support for other mean of installing Ansible.

`ansible-role` : This component is a wrapper around several things that are needed to run Ansible's playbook.  First and foremost each Ansible's role is loosely comparable to OneOps' component.  It is merely a wrapper and thus will not have all the features of OneOps' component.  It does however has the necessary features of a normal Ansible's playbook.

There are several ways of using this component and none is preferred over the other.

Use Case #1.  Single Role

>Specify the role name & version
	
>Specify the playbook, the following is a must to run the playbook properly.  The playbook will be running on the 'localhost' of the compute therefore the playbook must configured hosts to use 'all'.  Also the roles must be specified to the assigned role.
	
Use Case #2.  Multiple Role(s)

>This is the most versatile way of using Ansible's role.  In this usage the name & version of the role is not applicable.  
>
>Configure Source of which can be a single role or multiple roles.  You must follow the supported convention otherwise it will not work.  The following URL has the detail on what to use in this section: http://docs.ansible.com/ansible/galaxy.html#installing-multiple-roles-from-a-file 
>
> Finally, same as the last use case you must configure your playbook accordingly.