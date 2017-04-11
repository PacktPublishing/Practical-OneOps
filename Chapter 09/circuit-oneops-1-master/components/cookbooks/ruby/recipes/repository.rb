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
# Cookbook Name:: ruby
# Recipe:: repository
#

if node.platform == "ubuntu"

  [ 'ruby-full', 'rubygems1.8' ].each do |name|

    sleep rand(10)
    retry_count = 0
    while system('lsof /var/lib/dpkg/lock') && retry_count < 20
      Chef::Log.warn("Found lock. Will retry package #{name} in #{node.workorder.rfcCi.ciName}")
      sleep rand(5)+10
      retry_count += 1
    end

    package "#{name}" do
      action :install
    end

  end

  # needed for some gems
  if node.platform_version == "10.10"
    package "g++" do
      action :install
    end
  end

else

  package "ruby-devel"

end


# must fork gem cmdline or chef uses the current ruby gem install
_gems = JSON.parse(node.workorder.rfcCi.ciAttributes.gems)
_gems.each do |gem,opts|


bash "#{gem}" do
    code <<-EOH
      gem install #{gem} #{opts} --no-rdoc --no-ri
    EOH
  end
end

cookbook_file "/tmp/create_gem_bin_links.sh" do
  source "create_gem_bin_links.sh"
  mode "0755"
end

bash "links" do
  code <<-EOH
    /tmp/create_gem_bin_links.sh
  EOH
end


# check if we had rvm before and change it to use repository as default
bash "disable previous rvm installation" do
  code <<-EOH
source /etc/profile.d/rvm.sh
rvm use system --default
EOH
  only_if "test -f /etc/profile.d/rvm.sh"
end
