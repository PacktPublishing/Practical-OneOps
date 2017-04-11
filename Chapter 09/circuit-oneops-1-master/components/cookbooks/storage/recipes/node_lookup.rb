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

storage_cloud_name = node[:workorder][:cloud][:ciName]
storagecloud = node[:workorder][:services][:storage][storage_cloud_name][:ciAttributes]
volumetype_map= JSON.parse(storagecloud[:volumetypemap]) if !storagecloud[:volumetypemap].nil?

if volumetype_map.count == 0
  node.set[:volume_type_from_map] = ""
  return true
end

# Get the volume type from the volume type map
volume_type_selected = node.workorder.rfcCi.ciAttributes["volume_type"]
Chef::Log.debug("node_lookup volume_type_selected: #{volume_type_selected}")
if volumetype_map[volume_type_selected] != nil
   node.set[:volume_type_from_map] = volumetype_map[volume_type_selected]
else
	exit_with_error("Volume Type #{volume_type_selected} Not found")
end
