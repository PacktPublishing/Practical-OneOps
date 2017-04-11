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
    # Chef Provider for F5 LTM SSL Profiles
    #
    class F5LtmSslprofiles < Chef::Provider
      include F5::Loader

      # Support whyrun
      def whyrun_supported?
        false
      end

      def load_current_resource # rubocop:disable MethodLength
        @current_resource = Chef::Resource::F5LtmSslprofiles.new(@new_resource.name)
        @current_resource.name(@new_resource.name)
        @current_resource.sslprofile_name(@new_resource.sslprofile_name)

        sslprofile = load_balancer.ltm.sslprofiles.find { |p| p =~ /(^|\/)#{@new_resource.sslprofile_name}$/ }

        @current_resource.exists = !sslprofile.nil?

        return @current_resource unless @current_resource.exists

        # If pool exists load it's current state
      #  @current_resource.keyid(sslprofile.keyid)
      #  @current_resource.certid(sslprofile.certid)
      #  @current_resource.passphrase(sslprofile.passphrase)
        @current_resource
      end

      def action_create
        #create_sslprofile unless current_resource.exists
        create_sslprofile if load_balancer.ltm.sslprofiles.find { |p| p =~ /(^|\/)#{@new_resource.sslprofile_name}$/ }.nil?

        update_key_cert 

        update_passphrase 
      end

      def action_delete
        delete_sslprofile if current_resource.exists
      end

      private

      #
      # Create a new ssl profile given new_resource attributes
      #
      def create_sslprofile
        converge_by("Create #{new_resource} ssl profile") do
          Chef::Log.info "Create #{new_resource} ssl profile"


          load_balancer.client['LocalLB.ProfileClientSSL'].create_v2([new_resource.sslprofile_name], [{"value" => "/Common/#{new_resource.keyid}", "default_flag" => "false"}] , [{"value" => "/Common/#{new_resource.certid}", "default_flag" => "false"}])
          load_balancer.client['LocalLB.ProfileClientSSL'].set_passphrase(["/Common/#{new_resource.sslprofile_name}"], [{"value" => "#{new_resource.passphrase}", "default_flag" => "false" }]) if !new_resource.passphrase.nil?

          current_resource.keyid(new_resource.keyid)
          current_resource.certid(new_resource.certid)
          current_resource.cacertid(new_resource.cacertid)
          current_resource.passphrase(new_resource.passphrase)

          new_resource.updated_by_last_action(true)
        end
      end

      #
      # Set cert key  method given new_resource cert key attribute
      #
      def update_key_cert
        converge_by("Update #{new_resource} cert key  method") do
	  kid = new_resource.keyid
	  cid = new_resource.certid
          caid = new_resource.cacertid if !new_resource.cacertid.nil?
	  todel='-alt'
	  if @current_resource.exists
	    if !load_balancer.client['LocalLB.ProfileClientSSL'].get_key_file(["/Common/#{new_resource.sslprofile_name}"])[0].value.include?("#{new_resource.sslprofile_name}-alt")
		kid = new_resource.sslprofile_name+'-alt.key'
		cid = new_resource.sslprofile_name+'-alt.crt'
		caid = new_resource.sslprofile_name+'-alt.crt' if !new_resource.cacertid.nil?
		todel = ''
	    end
	  end
          Chef::Log.info "Update #{new_resource} cert key method with PASSPHRASE #{new_resource.passphrase}"
          load_balancer.client['LocalLB.ProfileClientSSL'].set_key_certificate_file([new_resource.sslprofile_name], [{"value" => "/Common/#{kid}", "default_flag" => "false"}] , [{"value" => "/Common/#{cid}", "default_flag" => "false"}])
          load_balancer.client['LocalLB.ProfileClientSSL'].set_passphrase(["/Common/#{new_resource.sslprofile_name}"], [{"value" => "#{new_resource.passphrase}", "default_flag" => "false" }]) if !new_resource.passphrase.nil?
          load_balancer.client['LocalLB.ProfileClientSSL'].set_chain_file_v2(["/Common/#{new_resource.sslprofile_name}"], [{"value" => "/Common/#{caid}", "default_flag" => "false" }]) if !new_resource.cacertid.nil?
	 
	  ssl_d = load_balancer.ltm.ssls("MANAGEMENT_MODE_DEFAULT").find { |p| p =~ /(^|\/)#{new_resource.sslprofile_name}#{todel}$/ } 
	  if !ssl_d.nil?
	  	load_balancer.client['Management.KeyCertificate'].key_delete("MANAGEMENT_MODE_DEFAULT", ["/Common/#{new_resource.sslprofile_name}#{todel}"])
	  	load_balancer.client['Management.KeyCertificate'].certificate_delete("MANAGEMENT_MODE_DEFAULT", ["/Common/#{new_resource.sslprofile_name}#{todel}"])
	  end
          current_resource.keyid(new_resource.keyid)
          current_resource.certid(new_resource.certid)
          current_resource.passphrase(new_resource.passphrase)
          current_resource.cacertid(new_resource.cacertid)

          new_resource.updated_by_last_action(true)
        end
      end

      #
      # Set passphrase  given new_resource passphrase parameter
      #
      def update_passphrase
        converge_by("Update #{new_resource} passphrase") do
          Chef::Log.info "Update #{new_resource} passphrase"
          load_balancer.client['LocalLB.ProfileClientSSL'].set_passphrase(["/Common/#{new_resource.sslprofile_name}"], [{"value" => "#{new_resource.passphrase}", "default_flag" => "false" }])
          current_resource.passphrase(new_resource.passphrase)

          new_resource.updated_by_last_action(true)
        end
      end

      #
      # Delete the ssl profile
      #
      def delete_sslprofile
        converge_by("Delete #{current_resource} sslprofile") do
          Chef::Log.info "Delete #{current_resource} pool"
          load_balancer.client['LocalLB.ProfileClientSSL'].delete_profile([current_resource.sslprofile_name])

          new_resource.updated_by_last_action(true)
        end
      end

    end
  end
end
