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

node.set[:apache][:listen_ports] = Array.new(JSON.parse(node.workorder.rfcCi.ciAttributes.ports))
node.set[:apache][:modules] = Array.new(JSON.parse(node.workorder.rfcCi.ciAttributes.modules))
node.set[:apache][:prefork] = Mash.new(JSON.parse(node.workorder.rfcCi.ciAttributes.prefork))
node.set[:apache][:worker] = Mash.new(JSON.parse(node.workorder.rfcCi.ciAttributes.worker))

if (node[:apache][:php_info] == 'false')
  node.set[:apache][:php_index_content] = "OK 200"
end

if node[:apache][:install_type]
  Chef::Log.info("Installation type #{node[:apache][:install_type]} - running recipe apache::#{node[:apache][:install_type]}")
  include_recipe "apache::#{node[:apache][:install_type]}"
else
  Chef::Log.info("Installation type not specified - running default recipe apache::repository")
  include_recipe "apache::repository"
end

# If the platform is CentOS 6.6 or RHEL 6.6 or newer, allow the user to control the TLS protocol and enable stronger ciphers.
if (node[:platform] == "centos" || node[:platform] == "redhat")
  if (node[:platform_version].to_f >= 6.6)
    node.set[:apache][:tls_ciphers] = "TLSv1:TLSv1.1:TLSv1.2:!MEDIUM:!LOW:!3DES:!EXP:!AECDH:!ADH:!DH:!RC4:!NULL"
    tlsProtocols = Array.new
    if (node[:apache][:tlsv1_protocol_enabled] == 'true')
      tlsProtocols.push("+TLSv1")
    end
    if (node[:apache][:tlsv11_protocol_enabled] == 'true')
      tlsProtocols.push("+TLSv1.1")
    end
    if (node[:apache][:tlsv12_protocol_enabled] == 'true')
      tlsProtocols.push("+TLSv1.2")
    end

    if (tlsProtocols.empty?)
      Chef::Log.warn("All TLS protocols were disabled.  Defaulting to TLSv1.2 only.")
      node.set[:apache][:tls_protocols] = "+TLSv1.2"
    else
      node.set[:apache][:tls_protocols] = tlsProtocols.join(" ")
    end
  end
end

template "/opt/nagios/libexec/check_apache.rb" do
  source "check_apache.rb.erb"
  mode 0755
  owner "oneops"
  group "oneops"
end
