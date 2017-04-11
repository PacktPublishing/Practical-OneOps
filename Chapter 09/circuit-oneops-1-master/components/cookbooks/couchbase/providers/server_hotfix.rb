##
# server_hotfix providers
#
# Apply couchbase server hotfixes
#
# @Author Alex Natale <anatale@walmartlabs.com>
##


action :apply_220_hotfix do
  #Chef::Log.info("****Couchbase Server version #{new_resource.version}*****")
  node_restart_time = 15
  couchbase_installed = `sudo rpm -qa | grep couchbase-server |  cut -d- -f1-3`
  couchbase_installed = couchbase_installed.strip!

  if new_resource.version != nil && new_resource.version == '2.2.0' && couchbase_installed == "couchbase-server-#{new_resource.version}"
    #Chef::Log.info("****Appling Couchbase 2.2.0 Hotfix**** \n**** Fix Started *****")
    log "Appling_Couchbase_2.2.0_Hotfix" do
      message "**** Fix Started *****"
      level :info
    end

    #Download hotfix 2.2.0
    dll_file = ::File.join(Chef::Config[:file_cache_path], '/', 'beam-2.2.0-XDCR-HF.tar')
    remote_file dll_file do
      source "#{new_resource.cbhotfix_220_url}"
      checksum new_resource.sha256 if !new_resource.sha256.empty?
      action :create_if_missing
    end

    #apply hotfix
    execute 'apply_hotfix' do
      command "sleep 15 && tar -xf #{dll_file} -C #{Chef::Config[:file_cache_path]}"
      action :run
    end

    #apply hotfix files
    execute 'apply_hffiles' do
      command "sleep 15 && cp /tmp/beams/* /opt/couchbase/lib/ns_server/erlang/lib/ns_server/ebin/"
      action :run
    end

    #apply hotfix for distributing the cluster manager's workload across CPU
    # gen env vars & update /opt/couchbase/bin/couchbase-server
    `grep "COUCHBASE_NS_SERVER_VM_EXTRA_ARGS" /opt/couchbase/bin/couchbase-server`
    if $?.to_i != 0
      #Chef::Log.info("adding erlang cluster manager flag to /opt/couchbase/bin/couchbase-server...")
      log "erlang_log" do
        message "adding erlang cluster manager flag to /opt/couchbase/bin/couchbase-server..."
        level :info
      end
      pattern = "\"/# limitations under the License./a export COUCHBASE_NS_SERVER_VM_EXTRA_ARGS='[\\\"+swt\\\", \\\"low\\\"]'\" /opt/couchbase/bin/couchbase-server"
      execute 'couchbase_erlang' do
        command "sudo sed -i #{pattern}"
        action :run
      end
      execute 'couchbase_restart_node' do
        command "sudo /etc/init.d/couchbase-server restart"
        action :run
      end
      node_restart_time = 180
    else
      #Chef::Log.info("erlang cluster manager flag is already set...")
      log "erlang_log" do
        message "erlang cluster manager flag is already set..."
        level :info
      end
    end

    # Restart node
    execute 'restart_cluster_manager_node' do
      command "sleep #{node_restart_time} && /opt/couchbase/bin/curl --data 'erlang:halt().' -u #{new_resource.user}:#{new_resource.pass} http://localhost:#{new_resource.port}/diag/eval"
      returns [0,52]
      action :run
    end

    #wait on node
    execute 'wait_on_node' do
      command "sleep 30 && cd #{Chef::Config[:file_cache_path]}"
      action :run
    end

    #Chef::Log.info("****Fix End *****")
    log "End_Couchbase_2.2.0_Hotfix" do
      message "****Fix End *****"
      level :info
    end
  end
end
