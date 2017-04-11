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
# storage::delete
#

max_retry_count = 5
cloud_name = node[:workorder][:cloud][:ciName]
provider_class = node[:workorder][:services][:storage][cloud_name][:ciClassName].downcase
include_recipe "shared::set_provider"           
dev_map = node.workorder.rfcCi.ciAttributes["device_map"]
if provider_class =~ /azure/
  Chef::Log.info("Deleting the data disk ...")
  include_recipe "azuredatadisk::delete" # delete the datadisk permanently 
  return true
end

unless dev_map.nil?
  dev_map.split(" ").each do |dev|
    dev_parts = dev.split(":")
    vol_id = dev_parts[0]
    Chef::Log.info("destroying: "+vol_id)
    ok = false
    retry_count = 0
    while !ok && retry_count < max_retry_count do
      ok = true
      volume = nil
      begin
        volume = node.storage_provider.volumes.get vol_id
      rescue => e
        Chef::Log.error("getting volume exception: "+e.message)
        next
      end                      
      
      begin
        unless volume.nil?
          volume.destroy
        end
      rescue => e
        if e.message !~ /does not exist|Storage Unit must be in the Active or Failed state/
          Chef::Log.error("volume destroy exception: "+e.message);
          ok = false
        end
      end 

      retry_count += 1
      if !ok            
        sleep_sec = retry_count * 5
        Chef::Log.error("sleeping #{sleep_sec}sec between retries...")
        sleep(sleep_sec) 
      end
    end
    if !ok
      error_key=JSON.parse(e.response[:body]).keys[0]
      msg = JSON.parse(e.response[:body])[error_key]['message']
      exit_with_error "couldnt destroy: #{vol_id} because #{msg} .. #{error_key}"
    end
  end
end       
