# Cookbook Name:: queue
# Recipe:: activemq_delete.rb
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

amq = node.workorder.payLoad[:activemq][0]
appresourcename = "#{node['queue']['queuename']}"
activemq_home = "#{amq[:ciAttributes][:installpath]}/activemq"
destsubtype = 'Q'
compositequeuedef = " #{node['queue']['virtualdestination']} "
if !compositequeuedef.strip!.empty? 
   destsubtype = 'compositeQueue'
end

execute "delete ActiveMQ Queue" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq"
  command "java -cp 'amq-messaging-resource.jar:*' io.strati.amq.MessagingResources -s 'localhost' -r deletequeue -dn #{appresourcename}"
  cmd = Mixlib::ShellOut.new(command).run_command
    if cmd.stdout.include? "Error"
       Chef::Log.error("Error occurred : #{cmd.stdout}")
      exit 1
    else
      Chef::Log.info("Execution completed: #{cmd.stdout}")
    end
end

ruby_block "Delete Destination Policy and composite queue" do
  block do
     Chef::Resource::RubyBlock.send(:include, Q2::Activemq_dest_config_util)
     Q2::Activemq_dest_config_util::deleteDestPolicy("#{activemq_home}/conf/activemq.xml", "#{destsubtype}", "#{appresourcename}")
     Q2::Activemq_dest_config_util::deleteVirtualDest("#{activemq_home}/conf/activemq.xml", "#{destsubtype}", "#{appresourcename}")
  end
end

execute "delete destination" do
   command "sed -i /#{node['queue']['destinationtype']}-#{appresourcename}-#{node['queue']['destinationtype']}/d #{activemq_home}/conf/activemq.xml"
end
