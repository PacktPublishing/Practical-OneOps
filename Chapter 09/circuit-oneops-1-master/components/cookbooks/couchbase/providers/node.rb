##
# node providers
#
# Create & set permission for couchbase data path
# Init couchbase node for data path
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

def whyrun_supported?
  true
end

use_inline_resources

action :create_data_path do
  #create couchbase data path structure and set permissions
  directory "#{new_resource.data_path}" do
    owner 'couchbase'
    group 'couchbase'
    mode  '0775'
    recursive true
    action :create
  end
end

action :init_couchbase_data_path do
  #start couchbase server if not running
  service "couchbase-server" do
    action :start
  end
  # Couchbase node initialization
  execute 'set_node_data_path' do
    command "sleep 15 && /opt/couchbase/bin/couchbase-cli node-init -c localhost:#{new_resource.port} --node-init-data-path=#{new_resource.data_path} -u #{new_resource.user} -p #{new_resource.pass}"
    returns [0,2]
    action :run
  end
end

action :set_ulimits_file do
    # Ulimit configuration
    limits_file = '/etc/security/limits.conf'
    `grep couchbase #{limits_file}`
    if $?.to_i != 0
      `echo "couchbase soft nofile 10240" >> #{limits_file}`
      `echo "couchbase hard nofile 10240" >> #{limits_file}`
    end
end
