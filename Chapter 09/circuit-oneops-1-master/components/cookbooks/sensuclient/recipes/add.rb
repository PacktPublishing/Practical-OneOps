#
# Cookbook Name:: Sensuclient
# Recipe:: add
#
# Copyright 2016, kaushiksriram100@gmail.com
#
# Apache 2.0
#
include_recipe "sensuclient::wire_ci_attr"

Chef::Log.info("I am starting sensu deployment")


platform_family = node["platform_family"]
cust_team = node[:sensuclient][:cust_team]
cust_subscriptions = node[:sensuclient][:cust_subscriptions]
endpoint = node[:sensuclient][:endpoint]
sensu_community_plugins = node[:sensuclient][:sensu_plugin_repo]
keepalive_handlers = node[:sensuclient][:keepalive_handlers]
rpm_url = node[:sensuclient][:rpm_url]

#arrange the subscriptions

tmp = cust_subscriptions.split(",")
subscriptions = tmp.map(&:inspect).join(', ')

#arrange handlers

tmp1 = keepalive_handlers.split(",")

#remove whitespaces
tmp1.map!{ |var| var.gsub(/\s+/, "")}
handlers = tmp1.map(&:inspect).join(', ')

#arrange the keys
tmp_cert_path="/tmp/cert.pem"
tmp_key_path="/tmp/key.pem"

cert_content=''
key_content=''

cert_content = node[:sensuclient][:sensu_client_cert]
key_content = node[:sensuclient][:sensu_client_key]

File.open(tmp_cert_path, "w") do |certfile|
        certfile.write(cert_content)
end
File.open(tmp_key_path, "w") do |keyfile|
        keyfile.write(key_content)
end

#get the rmq password

vhost_pwd = node[:sensuclient][:sensu_vhost_password]

#arrange the endpoints for message queue

endpoints = endpoint.split(",").reject(&:empty?)
endpoint_count = endpoints.length

#Limit to a max of 6 messaging end points

Chef::Log.info("Total sensu endpoints are #{endpoint_count}")

	case endpoint_count
	when 1
        	rabbitmq_endpoint_1 = endpoints[0]
	when 2
        	rabbitmq_endpoint_1 = endpoints[0]
        	rabbitmq_endpoint_2 = endpoints[1]
	when 3
                rabbitmq_endpoint_1 = endpoints[0]
                rabbitmq_endpoint_2 = endpoints[1]
		rabbitmq_endpoint_3 = endpoints[2]
	when 4
                rabbitmq_endpoint_1 = endpoints[0]
                rabbitmq_endpoint_2 = endpoints[1]
                rabbitmq_endpoint_3 = endpoints[2]
		rabbitmq_endpoint_4 = endpoints[3]
	when 5
                rabbitmq_endpoint_1 = endpoints[0]
                rabbitmq_endpoint_2 = endpoints[1]
                rabbitmq_endpoint_3 = endpoints[2]
                rabbitmq_endpoint_4 = endpoints[3]
                rabbitmq_endpoint_5 = endpoints[4]
	when 6
                rabbitmq_endpoint_1 = endpoints[0]
                rabbitmq_endpoint_2 = endpoints[1]
                rabbitmq_endpoint_3 = endpoints[2]
                rabbitmq_endpoint_4 = endpoints[3]
                rabbitmq_endpoint_5 = endpoints[4]
		rabbitmq_endpoint_6 = endpoints[5]
	else
		Chef::Log.info("NO RMQ ENDPOINTS captured still I will proceed and assign a default staging endpoint")
	end
	
	Chef::Log.info("platform family #{platform_family}")
	
	case platform_family
	when "rhel"
		sensu_client_version = node[:sensuclient][:sensu_client_version]
		system = `uname -m|tr --delete '\n'`
		mirror = "https://sensu.global.ssl.fastly.net/yum/7"
		rpm_package = sensu_client_version+"."+"el7"+"."+system+".rpm"
		package_url = mirror+"/"+system+"/"+rpm_package

		Chef::Log.info("Package URL is #{package_url}")

		#fetch the rpm
	        remote_file "/tmp/#{rpm_package}" do
			source "#{package_url}"
			action :create
			mode '0755'
			not_if "rpm -qa | grep -q '#{sensu_client_version}'"
		end
		
		Chef::Log.info("Fetched RPM")

		rpm_package "#{rpm_package}" do
			source "/tmp/#{rpm_package}"
			action :install
			notifies :restart, 'service[sensu-client]', :delayed
			not_if "rpm -qa | grep -q '#{sensu_client_version}'"
		end
		
		 #Modify client.json
		v_hostname=`hostname -f`.strip
		v_host_ip=`hostname -i`.strip
		template '/etc/sensu/conf.d/client.json' do
			source 'client.json.erb'
			mode '0440'
			owner 'sensu'
			group 'sensu'
			variables({
				:hostname => v_hostname,
				:host_ip => v_host_ip,
				:subscriptions => subscriptions,
                      		:team => cust_team,
                        	:application => node[:sensu][:application],
				:nspath => node[:sensu][:nspath],
                        	:handlers => handlers
                	})
       		         notifies :restart, 'service[sensu-client]', :delayed
	        end

			#create SSL directory
			directory "/etc/sensu/ssl" do
                		owner 'sensu'
                		group 'sensu'
                		mode '0755'
                		action :create
        		end

			#create the SSL cert and key files
				file "/etc/sensu/ssl/cert.pem" do
					owner 'sensu'
					group 'sensu'
					mode 0640
					content ::File.open("/tmp/cert.pem").read
					action :create
					notifies :restart, 'service[sensu-client]', :delayed
				end
				file "/etc/sensu/ssl/key.pem" do
                                        owner 'sensu'
                                        group 'sensu'
                                        mode 0640
                                        content ::File.open("/tmp/key.pem").read
                                        action :create
					notifies :restart, 'service[sensu-client]', :delayed
                                end
			#remove the tmp certs and keys

			`rm -rf /tmp/cert.pem`
			`rm -rf /tmp/key.pem`
			

			#Add rabbitmq configuration files.
			if endpoint_count == 1                
				template '/etc/sensu/conf.d/rabbitmq.json' do
                        		source 'rabbitmq_1.json.erb'
                        		mode '0440'
                        		owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			elsif endpoint_count == 2
				template '/etc/sensu/conf.d/rabbitmq.json' do
	                        	source 'rabbitmq_2.json.erb'
        	                	mode '0440'
                	        	owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
                                		:rabbitmq_endpoint_2 => rabbitmq_endpoint_2,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			elsif endpoint_count == 3
				template '/etc/sensu/conf.d/rabbitmq.json' do
                        		source 'rabbitmq_3.json.erb'
                        		mode '0440'
                        		owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
                                		:rabbitmq_endpoint_2 => rabbitmq_endpoint_2,
                                		:rabbitmq_endpoint_3 => rabbitmq_endpoint_3,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			elsif endpoint_count == 4
				template '/etc/sensu/conf.d/rabbitmq.json' do
                        		source 'rabbitmq_4.json.erb'
                        		mode '0440'
                        		owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
                                		:rabbitmq_endpoint_2 => rabbitmq_endpoint_2,
                                		:rabbitmq_endpoint_3 => rabbitmq_endpoint_3,
                                		:rabbitmq_endpoint_4 => rabbitmq_endpoint_4,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			elsif endpoint_count == 5
				template '/etc/sensu/conf.d/rabbitmq.json' do
                        		source 'rabbitmq_5.json.erb'
                        		mode '0440'
                        		owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
                                		:rabbitmq_endpoint_2 => rabbitmq_endpoint_2,
                                		:rabbitmq_endpoint_3 => rabbitmq_endpoint_3,
                                		:rabbitmq_endpoint_4 => rabbitmq_endpoint_4,
                                		:rabbitmq_endpoint_5 => rabbitmq_endpoint_5,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			elsif endpoint_count == 6
				template '/etc/sensu/conf.d/rabbitmq.json' do
                        		source 'rabbitmq_6.json.erb'
                        		mode '0440'
                        		owner 'sensu'
                        		group 'sensu'
                        		variables({
                                		:rabbitmq_endpoint_1 => rabbitmq_endpoint_1,
                                		:rabbitmq_endpoint_2 => rabbitmq_endpoint_2,
                                		:rabbitmq_endpoint_3 => rabbitmq_endpoint_3,
                                		:rabbitmq_endpoint_4 => rabbitmq_endpoint_4,
                                		:rabbitmq_endpoint_5 => rabbitmq_endpoint_5,
                                		:rabbitmq_endpoint_6 => rabbitmq_endpoint_6,
						:rabbitmq_vhost_password => vhost_pwd
                        		})
                         		notifies :restart, 'service[sensu-client]', :delayed
				end
			else
				cookbook_file "/etc/sensu/conf.d/rabbitmq.json" do
					source "rabbitmq.json"
					owner 'sensu'
					group 'sensu'
					mode '0640'
                                	action :create
                                	notifies :restart, 'service[sensu-client]', :delayed
                        	end
			end

		#Add sensu env variable
		cookbook_file '/etc/default/sensu' do
                       source 'sensu'
                       owner 'root'
                       group 'root'
                       mode '0755'
                       action :create
                       notifies :restart, 'service[sensu-client]', :delayed
                end

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
				tar zxvf /usr/lib/sensu-community/sensu-community-oneops.tar.gz
				chown -R root:root /usr/lib/sensu-community/
			EOS
			notifies :restart, 'service[sensu-client]', :delayed
		end

		#Remove the sensu-server startup script
        	file '/etc/init.d/sensu-server' do
          		action :delete
        	end

		service 'sensu-client' do
                	supports :status => true, :restart => true
                	action [ :enable, :start ]
        	end
	else
        	raise "Unsupported Linux platform"
	end

