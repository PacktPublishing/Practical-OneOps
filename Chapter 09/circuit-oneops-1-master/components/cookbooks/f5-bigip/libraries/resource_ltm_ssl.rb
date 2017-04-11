#
# Author:: Jacob McCann (<jacob.mccann2@target.com>)
# Cookbook Name:: f5-bigip
# Resource:: ltm_node
#
# Copyright:: 2014, Target Corporation
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

class Chef
  class Resource
    #
    # Chef Resource for F5 LTM Node
    #
    class  F5LtmSsl < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :f5_ltm_ssl
        @provider = Chef::Provider::F5LtmSsl
        @action = :create
        @allowed_actions = [:create, :delete]

        # This is equivalent to setting :name_attribute => true
        #@node_name = name

        # Now we need to set up any resource defaults
        @enabled = true
      end

      def cert_location(arg = nil)
        set_or_return(:cert_location, arg, :kind_of => String, :required => true)
      end

      def key_location(arg = nil)
        set_or_return(:key_location, arg, :kind_of => String, :required => true)
      end

      def cacert_location(arg = nil)
        set_or_return(:cacert_location, arg, :kind_of => String, :required => false)
      end

      def mode(arg = nil)
        set_or_return(:mode, arg, :kind_of => String, :required => true)
      end

      def f5(arg = nil)
        set_or_return(:f5, arg, :kind_of => String, :required => true)
      end

      def ssl_id(arg = nil)
        set_or_return(:ssl_id, arg, :kind_of => String, :required => true)
      end

      attr_accessor :exists
    end
  end
end
