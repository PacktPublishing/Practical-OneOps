# Cookbook Name:: topic
# Recipe:: activemq.rb
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
activemq_home = "#{amq[:ciAttributes][:installpath]}/activemq"
authtype = "#{amq[:ciAttributes][:authtype]}"
destsubtype = 'T'
compositetopicdef = " #{node['topic']['compositetopic']} "
if !compositetopicdef.strip!.empty? 
   destsubtype = 'compositeTopic'
   compositevirtualtopic = "#{compositetopicdef}"
end
virtualtopicdef = " #{node['topic']['virtualdestination']} "
if !virtualtopicdef.strip!.empty? 
   destsubtype = 'virtualTopic'
   compositevirtualtopic = "#{virtualtopicdef}"
end
if !(compositetopicdef.empty? || virtualtopicdef.empty?)
   errorMsg =  "#{node['topic']['topicname']} can only has one non-empty entry for virtual topic or composite topic, not both"
   puts "***FAULT:FATAL=#{errorMsg}"
   raise "#{errorMsg}"
end


action ='false'
if node.workorder.rfcCi.rfcAction == 'add' || node.workorder.rfcCi.rfcAction == 'replace'
    action='true'
end

fullname = "#{node['topic']['topicname']}"
fullname.strip!

node.set[:topic][:appdir] = "#{node.workorder.payLoad[:activemq][0][:ciAttributes][:installpath]}/activemq"

    readuserval =''
    writeuserval=''

  JSON.parse(node['topic']['permission']).map{ |k,v|
    if "#{v}" == 'RW'
        readuserval << "#{k}" << ","
        writeuserval <<  "#{k}" << ","
    elsif "#{v}" == 'R'
       readuserval << "#{k}" << ","
    elsif "#{v}" == 'W'
       writeuserval <<  "#{k}" << ","
    end
  }
    readuserval == nil ? nil : readuserval.chomp!(",")
    writeuserval == nil ? nil : writeuserval.chomp!(",")

template "/tmp/#{fullname}-groups.properties" do
  source 'groups.properties.erb'
  variables({
        :adminusername => amq[:ciAttributes][:adminusername],
        :destinationname => fullname,
        :permission => node['topic']['permission'],
        :read => readuserval,
        :write => writeuserval
      })
  mode 0644
  only_if {authtype  == 'JAAS'}
end

bash "handle groups" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq/conf"
  code <<-EOH
    sed -i "/#{fullname}/d" groups.properties
    cat "/tmp/#{fullname}-groups.properties" >> groups.properties
  EOH
  only_if {authtype  == 'JAAS'}
  only_if { File.exists?("/#{activemq_home}/conf/groups.properties") }
end


template "#{activemq_home}/conf/auth.txt" do
  source 'auth.txt.erb'
  variables({
        :adminusername => amq[:ciAttributes][:adminusername],
        :destinationname => fullname,
        :destinationtype => node['topic']['destinationtype'],
        :authtype => amq[:ciAttributes][:authtype],
        :permission => node['topic']['permission'],
        :users => amq[:ciAttributes][:users]
      })
  mode 0644
end

template "#{activemq_home}/conf/simple.txt" do
  source 'simple.txt.erb'
  variables({
        :destinationname => fullname,
        :destinationtype => node['topic']['destinationtype'],
        :authtype => amq[:ciAttributes][:authtype],
        :permission => node['topic']['permission'],
        :users => amq[:ciAttributes][:users],
        :read => readuserval,
        :write => writeuserval
      })
  mode 0644
  only_if {authtype  == 'Simple'}
end

bash "handle Simple Auth" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq/conf"
    code <<-EOH
    sed -i -e "/<users>/r simple.txt" activemq.xml
  EOH
end

bash "handle destination auth" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq/conf"
  code <<-EOH
    sed -i s/destinationname/#{fullname}/g auth.txt
    sed -i s/#{node['topic']['destinationtype']}-#{fullname}-#{node['topic']['destinationtype']}/#{node['topic']['destinationtype']}-#{fullname}-#{node['topic']['destinationtype']}-delete/g activemq.xml
    sed -i "/<authorizationEntries>/a $(cat auth.txt)" activemq.xml
    sed -i /#{node['topic']['destinationtype']}-#{fullname}-#{node['topic']['destinationtype']}-delete/d activemq.xml
  EOH
end

ruby_block "Handle Destination Policy and virtual destination" do
  block do
     Chef::Resource::RubyBlock.send(:include, Topic::Activemq_dest_config_util)
     Chef::Log.info("Process virtual destination definition: #{node['topic']['virtualdestination']}")
     Topic::Activemq_dest_config_util::processVirtualDest("#{activemq_home}/conf/activemq.xml", "#{destsubtype}", "#{fullname}", "#{compositevirtualtopic}")
     Chef::Log.info("Process destination policy: #{node['topic']['destinationpolicy']} ")
     Topic::Activemq_dest_config_util::processDestPolicy("#{activemq_home}/conf/activemq.xml", "#{destsubtype}", "#{fullname}", "#{node['topic']['destinationpolicy']}")
  end
end

execute "ActiveMQ Topic" do
  cwd "#{amq[:ciAttributes][:installpath]}/activemq"
  command "java -cp 'amq-messaging-resource.jar:*' io.strati.amq.MessagingResources  -s '#{node[:fqdn]}' -r topic  -dn #{fullname}	 -mm  #{node[:topic][:maxmemorysize]}"
  cmd = Mixlib::ShellOut.new(command).run_command
    if cmd.stdout.include? "Error"
       Chef::Log.error("Error occurred : #{cmd.stdout}")
      exit 1
    else
      Chef::Log.info("Execution completed: #{cmd.stdout}")
    end
    only_if { destsubtype == 'T' }
end

template '/opt/nagios/libexec/check_amq_topic.rb' do
  source 'check_amq_topic.rb.erb'
  mode 0755
  owner 'oneops'
  group 'oneops'
end
