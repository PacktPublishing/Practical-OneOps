# Copyright 2016, Walmart Stores, Inc.
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
# Cookbook Name:: volume 
# Recipe:: log-grep
#

require 'json'

args = ::JSON.parse(node.workorder.arglist)

start_line= args["StartAtLine"]
end_line=args["EndAtLine"]
#file_names="/app/file_1.txt /app/file_2.txt"
file_names=args["Files"]
search_pattern=args["SearchRegexPattern"]

if file_names.to_s.strip.length == 0
        Chef::Log.error("\"Files\" parameter not specified")
        return
end

if search_pattern.to_s.strip.length == 0
        Chef::Log.error("\"SearchRegexPattern\" parameter not specified")
        return
end

if start_line.to_s.strip.length == 0
	start_line = 0
end

cmd_str = "awk 'FNR >= #{start_line}"

if ! (end_line.to_s.strip.length == 0)
     cmd_str.concat(" && FNR <= #{end_line}")
end

ciId = node.workorder.payLoad.ManagedVia[0][:ciId].to_s.strip

cmd_str.concat(" &&/#{search_pattern}/ { print #{ciId},FILENAME,\"line#\"FNR,$0 }' #{file_names}")

#cmd_str.concat(" &&/#{search_pattern}/ { print \"ciId-\" ENVIRON[\"ONEOPS_COMPUTE_CI_ID\"],FILENAME,\"line#\"FNR,$0 }' #{file_names}")

puts "\n"

cmd = Mixlib::ShellOut.new(cmd_str)
cmd.run_command
puts "\n"

Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")

