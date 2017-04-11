require 'date'

cloud_name = node[:workorder][:cloud][:ciName]
provider = ""
auto_provision = node.workorder.rfcCi.ciAttributes.auto_provision
cert_service = node[:workorder][:services][:certificate]

if ! cert_service.nil? && ! cert_service[cloud_name].nil?
	provider = node[:workorder][:services][:certificate][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
elsif !auto_provision.nil? && auto_provision == "true"
        Chef::Log.error("Certificate cloud service not defined for this cloud")
        exit 1
end

expires_on = node[:expiry_time]

if !auto_provision.nil? && auto_provision == "true" && !provider.nil? && !provider.empty?
	include_recipe provider + "::add_certificate" 
	expires_on = node[:expiry_time]
end

expires_in_value_changed = false

if (node.workorder.rfcCi.ciBaseAttributes.has_key?("expires_in") && node.workorder.rfcCi.ciAttributes.expires_in != node.workorder.rfcCi.ciBaseAttributes.expires_in)
	Chef::Log.info("expires_in value changed by user..")
	expires_in_value_changed = true
end

#below code for writing the perf metrics for cert expirty time remaining

if expires_on.nil? || expires_in_value_changed == true #auto provision is turned off or this is first time deployment or user changed the expires_in value
	expires_in = node[:certificate][:expires_in]
	if ((expires_in.nil? || expires_in.empty?) || ! (expires_in.end_with?("y") || expires_in.end_with?("m") || expires_in.end_with?("d")) || expires_in.length < 2 )
		Chef::Log.info("expiry attribute empty or does not end with y|m|d")
	else
		Chef::Log.info("expires_in value: " + expires_in)
		last_char = expires_in.slice(expires_in.split('').last)
		Chef::Log.info("expires_in ends with: " + last_char.to_s)
		expires_in=expires_in.chop #remove the last letter
		time_now = DateTime.now

		if last_char == 'y'
			expires_on = (time_now >> (expires_in.to_i) * 12)    
		elsif last_char == 'm'
			expires_on = (time_now >> (expires_in.to_i))					
                elsif last_char == 'd'
                        expires_on = (time_now + expires_in.to_i)
		end

        	#expires_on = Time.at(expires_on)
	end
end

if !expires_on.nil?
	Chef::Log.info("expiry time to be set in monitor metrics: " + Time.parse(expires_on.to_s).to_i.to_s)
	node.set[:expiry_date_in_seconds] = Time.parse(expires_on.to_s).to_i

        template "/opt/nagios/libexec/check_cert" do
        	source "check_cert.erb"
                owner "oneops"
                group "oneops"
                mode "0755"
                end

	puts "***RESULT:expires_on=" + expires_on.to_s
else
        node.set[:expiry_date_in_seconds] = nil
end
