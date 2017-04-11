#
# Author:: Jacob McCann (<jacob.mccann2@target.com>)
# Cookbook Name:: f5-bigip
# Provider:: ltm_pool
#
# Copyright:: 2013, Target Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Provider
    #
    # Chef Provider for F5 LTM SSL
    #
    class F5LtmSsl < Chef::Provider
      include F5::Loader

      # Support whyrun
      def whyrun_supported?
        false
      end

      def load_current_resource # rubocop:disable MethodLength
        @current_resource = Chef::Resource::F5LtmSsl.new(@new_resource.name)
        @current_resource.name(@new_resource.name)

        ssl_detail = load_balancer.ltm.ssls("#{new_resource.mode}").find { |p| p =~ /(^|\/)#{@new_resource.ssl_id}$/ }
        ssl_detail_alt = load_balancer.ltm.ssls("#{new_resource.mode}").find { |p| p =~ /(^|\/)#{@new_resource.ssl_id}-alt$/ }

	@current_resource.exists = true if !ssl_detail.nil? || !ssl_detail_alt.nil?

        return @current_resource unless @current_resource.exists

        # If pool exists load it's current state
        #@current_resource.cert_location(ssl_detail.cert_location)
        #@current_resource.key_location(ssl_detail.key_location)
        #@current_resource.mode(ssl_detail.mode)
        #@current_resource.ssl_id(ssl_detail.ssl_id)
        @current_resource
      end

      def action_create
	
	if !current_resource.exists || load_balancer.client['LocalLB.ProfileClientSSL'].get_key_file(["/Common/#{new_resource.ssl_id}"])[0].value.include?("#{new_resource.ssl_id}-alt")
		create_ssl('')
	elsif !load_balancer.client['LocalLB.ProfileClientSSL'].get_key_file(["/Common/#{new_resource.ssl_id}"])[0].value.include?("#{new_resource.ssl_id}-alt")
        	create_ssl('-alt') 
	end
	#update_key_location unless current_resource.key_location == new_resource.key_location
	#update_cert_location unless current_resource.cert_location == new_resource.cert_location
	#update_mode unless current_resource.mode == new_resource.mode

      end

      def action_delete
        delete_ssl if current_resource.exists
      end

      private

      #
      # Create a new ssl profile given new_resource attributes
      #
      def create_ssl(type)
        converge_by("Create #{new_resource} ssl#{type} ") do
          Chef::Log.info "Create #{new_resource} ssl#{type}"
	  # Clean Up of existing unused keys and certificates
	  if !load_balancer.ltm.ssls("#{new_resource.mode}").find { |p| p =~ /(^|\/)#{new_resource.ssl_id}#{type}$/ }.nil?
          	load_balancer.client['Management.KeyCertificate'].key_delete("MANAGEMENT_MODE_DEFAULT", ["/Common/#{new_resource.ssl_id}#{type}"])
          	load_balancer.client['Management.KeyCertificate'].certificate_delete("MANAGEMENT_MODE_DEFAULT", ["/Common/#{new_resource.ssl_id}#{type}"])
	  end

          key_content_blob = ::File.open("#{new_resource.key_location}", "rb").read
          cert_content_blob = ::File.open("#{new_resource.cert_location}", "rb").read
          cacert_content_blob = ::File.open("#{new_resource.cacert_location}", "rb").read if !new_resource.cacert_location.nil?
          load_balancer.client['Management.KeyCertificate'].certificate_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}#{type}"], [cert_content_blob],'true')
          load_balancer.client['Management.KeyCertificate'].key_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}#{type}"], [key_content_blob],'true')
          load_balancer.client['Management.KeyCertificate'].certificate_import_from_pem("#{new_resource.mode}", ["cacert-#{new_resource.ssl_id}#{type}"], [cacert_content_blob],'true') if !cacert_content_blob.nil?

          new_resource.updated_by_last_action(true)
        end
      end

      def create_ssl_alt
	converge_by("Create #{new_resource} ssl_alt ") do
	  key_content_blob = ::File.open("#{new_resource.key_location}", "rb").read
	  cert_content_blob = ::File.open("#{new_resource.cert_location}", "rb").read
          cacert_content_blob = ::File.open("#{new_resource.cacert_location}", "rb").read if !new_resource.cacert_location.nil?
          load_balancer.client['Management.KeyCertificate'].certificate_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}-alt"], [cert_content_blob],'true')
          load_balancer.client['Management.KeyCertificate'].key_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}-alt"], [key_content_blob],'true')
          load_balancer.client['Management.KeyCertificate'].certificate_import_from_pem("#{new_resource.mode}", ["cacert-#{new_resource.ssl_id}-alt"], [cacert_content_blob],'true') if !cacert_content_blob.nil?
	end
      end

      #
      # Set cert key  method given new_resource cert key attribute
      #
      def update_key_location
        converge_by("Update #{new_resource} key location") do
          Chef::Log.info "Update #{new_resource} key location"
          key_content_blob = File.open("#{new_resource.key_location}", "rb").read
          load_balancer.client['Management.KeyCertificate'].key_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}"], [key_content_blob],'true')
          current_resource.key_location(new_resource.key_location)

          new_resource.updated_by_last_action(true)
        end
      end

      def update_cert_location
        converge_by("Update #{new_resource} cert location") do
          Chef::Log.info "Update #{new_resource} cert location"
          cert_content_blob = File.open("#{new_resource.cert_location}", "rb").read
          load_balancer.client['Management.KeyCertificate'].key_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}"], [cert_content_blob],'true')
          current_resource.cert_location(new_resource.cert_location)

          new_resource.updated_by_last_action(true)
        end
      end

      def update_mode
        converge_by("Update #{new_resource} mode location") do
          Chef::Log.info "Update #{new_resource} mode location"
          load_balancer.client['Management.KeyCertificate'].key_import_from_pem("#{new_resource.mode}", ["#{new_resource.ssl_id}"], [cert_content_blob],'true')
          current_resource.mode(new_resource.mode)

          new_resource.updated_by_last_action(true)
        end
      end
      
      def delete_ssl
        converge_by("Update #{new_resource} mode location") do
          Chef::Log.info "Update #{new_resource} mode location"
          load_balancer.client['Management.KeyCertificate'].key_delete("#{new_resource.mode}", ["/Common/#{new_resource.ssl_id}"])
          load_balancer.client['Management.KeyCertificate'].certificate_delete("#{new_resource.mode}", ["/Common/#{new_resource.ssl_id}"])
        end

      end

    end
  end
end
