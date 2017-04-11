dir=run_context.cookbook_collection["couchbase"].root_dir

Chef::Log.info dir

require "#{dir}/libraries/couchbase_bucket"
require "#{dir}/libraries/couchbase_cli"
require "#{dir}/libraries/couchbase_cluster"
require "#{dir}/libraries/couchbase_node"
require "#{dir}/libraries/couchbase_process"
require "#{dir}/libraries/couchbase_reset_password"
require "#{dir}/libraries/couchbase_rest"
require "#{dir}/libraries/util/remote_ssh"
require "#{dir}/libraries/component/bucket_component"
require "#{dir}/libraries/component/couchbase_component"
require "#{dir}/libraries/component/ring_component"
require "#{dir}/libraries/component/precbhook"
require "#{dir}/libraries/component/cbcluster_component"
require "#{dir}/libraries/component/diagnostic_cache_component"
require "#{dir}/libraries/workorder_factory"

component = Couchbase::Factory::WorkOrderFactory.init(node)

if component
    component.execute
end
