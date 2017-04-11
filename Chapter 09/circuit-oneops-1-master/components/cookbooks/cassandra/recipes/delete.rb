
nodetool = "/opt/cassandra/bin/nodetool"
availability_mode = node.workorder.box.ciAttributes.availability
if availability_mode != "single"
  ruby_block 'decomm' do
    block do
      result = `#{nodetool} decommission 2>&1`
      if $? != 0 && result !~ /pointless/
        Chef::Log.error("decommission failed with: #{result}")
        exit 1
      end
    end
    only_if "#{nodetool} info"
  end
end

service "cassandra" do
  action [ :disable, :stop ]
end