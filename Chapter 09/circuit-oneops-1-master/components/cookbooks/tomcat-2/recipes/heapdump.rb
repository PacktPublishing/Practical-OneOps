# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: tomcat-2
# Recipe:: heapdump
# Purpose:: This recipe is used to create a heapdump and put in into
#           the catalina.out file.
#
# Copyright 2016, Walmart Stores Incorporated
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
###############################################################################
proc_id=`pgrep -f "org.apache.catalina.startup.Bootstrap"`
proc_id=proc_id.chomp
Chef::Log.info("proc_id = #{proc_id}")

tomcatuserid=`ps aux | grep java | grep -v grep | awk '{print $1}'`
tomcatuserid=tomcatuserid.chomp
Chef::Log.info("tomcatuserid = #{tomcatuserid}")

timestamp=`date +%m_%d_%y_%H_%M_%S`
timestamp=timestamp.chomp
Chef::Log.info("timestamp = #{timestamp}")

heap_dump_cmd="sudo -u #{tomcatuserid} jmap -dump:file=/opt/tomcat/logs/heapdump-#{timestamp}.hprof #{proc_id}"
Chef::Log.info("heap_dump_cmd = #{heap_dump_cmd}")

puts "Command is #{heap_dump_cmd}"
if !proc_id.empty?
  ruby_block "jstack_output" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      cmdout =  shell_out!(heap_dump_cmd,
               :live_stream => Chef::Log::logger)
    end
  end
   if ($?.exitstatus).eql?(0)
    Chef::Log.info("Heap Dump Completed")
   else
    Chef::Log.error("Please ensure JDK is installed")
   end
else
  Chef::Log.error("Please ensure tomcat is running")
end
