#
# Cookbook Name:: f5-bigip
# Provider:: config_sync
#

class Chef
  class Provider
    #
    # Chef Provider for F5 Config Sync
    #
    class F5ConfigSync < Chef::Provider
      include F5::Loader

      def load_current_resource
        @current_resource ||= Chef::Resource::F5ConfigSync.new(new_resource.name)
        @current_resource.f5(new_resource.f5)
        @current_resource
      end

      # Support whyrun
      def whyrun_supported?
        false
      end

      def action_run
        synchronize_to_all_groups if load_balancer.active?
      end

      private

      #
      # Push config to peers
      #
      def synchronize_to_all_groups
        Chef::Log.info "No peers for #{load_balancer.system_hostname}" if load_balancer.device_groups.empty?
        return if load_balancer.device_groups.empty?

        converge_by("Pushing configs from #{new_resource.f5} to peers") do
          Chef::Log.info "Pushing configs from #{new_resource.f5} to peers"

          load_balancer.device_groups.each do |grp|
            Chef::Log.info "  Pushing config from #{load_balancer.system_hostname} to group #{grp}"
            load_balancer.client['System.ConfigSync'].synchronize_to_group_v2(grp, load_balancer.system_hostname, true)
            new_resource.updated_by_last_action(true)
          end
        end
      end
    end
  end
end
