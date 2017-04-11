#
# Cookbook Name:: Sensuclient
# Recipe:: updateplugins
#
# Copyright 2016, kaushiksriram100@gmail.com
#
# Apache 2.0 
#

Chef::Log.info("I am updating plugins")


platform_family = node["platform_family"]
sensu_community_plugins = node[:sensuclient][:sensu_plugin_repo]

	Chef::Log.info("platform family #{platform_family}")
	
	case platform_family
	when "rhel"

		#create a plugin directory
		`mkdir -p /usr/lib/sensu-community`


		remote_file "/usr/lib/sensu-community/sensu-community-oneops.tar.gz" do
			source "#{sensu_community_plugins}"
			owner 'root'
			group 'root'
			action :create
			mode '0755'
			notifies :restart, 'service[sensu-client]', :delayed
		end

		script "untar_plugins" do
			interpreter "bash"
			user 'root'
			group 'root'
			cwd "/usr/lib/sensu-community"
			code <<-EOS
				rm -rf /usr/lib/sensu-community/sensu-community
				tar zxvf /usr/lib/sensu-community/sensu-community-oneops.tar.gz
				chown -R root:root /usr/lib/sensu-community/
			EOS
			notifies :restart, 'service[sensu-client]', :delayed
		end

		service 'sensu-client' do
                	supports :status => true, :restart => true
                	action [ :enable, :start ]
        	end
	else
        	raise "Unsupported Linux platform"
	end

