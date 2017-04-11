module Couchbase
  module Component
    class Precbhook
      attr_accessor :workorder, :public_ips, :action, :public_remove_ips, :admin_username, :admin_password, :couchbase_cli, :ssh_key_file

      def initialize(workorder)

        @workorder=workorder
        @public_ips=Array.new
        @public_remove_ips=Array.new
        parse_workorder

      end

      def execute

        if @action == "precbhook::update"

        end
        if @action == "precbhook::replace"
          replace
        end

      end

      def replace

        server_action=check_server_health_replace

        case server_action

          when "remove_node"
            remove_node_rebalance
          when "failover_node"
            failover_node_rebalance
          else
            Chef::Application.fatal!("Unable to remove node(s). One of the nodes is unhealthy/inactive")
        end


      end

      def check_server_health_replace

        replace_action="remove_node"

        @couchbase_cli=Couchbase::CouchbaseCLI.new(@public_ips.first, @admin_username, @admin_password)

        rs = execute_ssh_command(@public_ips.first, @couchbase_cli.list_nodes_command)

        if rs.include?("Network is unreachable") || rs.include?("Connection refused")
          Chef::Application.fatal!(rs)
        end

        if rebalance_running
          Chef::Application.fatal!("Rebalance in progress! Unable to remove node.")
        end

        if !nodes_match(rs)
          Chef::Application.fatal!("The compute numbers in OneOps do not match the ones in couchbase.")
        end

        if !all_healthy(rs)
          Chef::Application.fatal!("Unable to remove node(s).")
        end

        if remove_node_unhealthy(rs)
          replace_action="failover_node"
        end

        replace_action

      end

      def rebalance_running
        command=@couchbase_cli.build_command("rebalance-status")
        rs = execute_ssh_command(@public_ips.first, command)
        if rs.include?("u'running'")
          return true
        end
        return false
      end

      def remove_node_rebalance

        #when public ip length is 0, executing single node
        if (@public_ips.length > 0)
          @couchbase_cli=Couchbase::CouchbaseCLI.new(@public_ips.first, @admin_username, @admin_password)
          command=@couchbase_cli.remove_nodes_command(@public_remove_ips)
          rs = execute_ssh_command(@public_ips.first, command)
          Chef::Log.info rs
        end

      end

      def failover_node_rebalance
        if (@public_ips.length > 0)
          @couchbase_cli=Couchbase::CouchbaseCLI.new(@public_ips.first, @admin_username, @admin_password)
          command=@couchbase_cli.fail_over_nodes_command(@public_remove_ips)
          rs = execute_ssh_command(@public_ips.first, command)
          Chef::Log.info rs
          command=@couchbase_cli.build_command("rebalance")
          rs = execute_ssh_command(@public_ips.first, command)
          Chef::Log.info rs
        end
      end


      def update_action


      end

      def execute_ssh_command(host, command)

        create_ssh_key
        command="ssh -i #{@ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{host} #{command}"
        result = %x[ #{command} ]
        delete_ssh_file

        result

      end

      private

      def remove_node_unhealthy(list)

        list.each_line { |line|

          data =line.split(' ')

          if @public_remove_ips.include?(data[0].split('@')[1])

            if data[2] == 'unhealthy'
              return true
            end

          end

        }

        false

      end

      def nodes_match(list)


        data =list.split(/\n/)

        if data.size == @public_ips.size || data.size == (@public_ips.size + @public_remove_ips.size)
          return true
        end

        return false

      end

      def all_healthy(list)

        list.each_line { |line|

          data =line.split(' ')

          if @public_remove_ips.include?(data[0].split('@')[1])
            next
          end

          if data[2] != 'healthy'
            return false
          end

          if data[3] != 'active'
            return false
          end

        }
      end


      def parse_workorder

        parse_required_computes
        parse_credentials

      end

      def parse_credentials

        if @workorder.payLoad.has_key?("hkcb")
          hkcb=@workorder.payLoad["hkcb"]
          hkcb.each { |attribute|
            if attribute["ciAttributes"].has_key?("adminuser")
              @admin_username=attribute["ciAttributes"]["adminuser"]
            end
            if attribute["ciAttributes"].has_key?("adminpassword")
              @admin_password=attribute["ciAttributes"]["adminpassword"]
            end
          }

        end

      end

      def parse_required_computes

        if @workorder.payLoad.has_key?("hkcomp")
          requires_computes=@workorder.payLoad["hkcomp"]
        end

        if !requires_computes.empty? && requires_computes.size > 0
          requires_computes.each { |attribute|

            if attribute["ciAttributes"].has_key?("public_ip")
              @public_ips.push(attribute["ciAttributes"]["public_ip"])
              ip = attribute["ciAttributes"]["public_ip"]
              hypervisor = attribute["ciAttributes"]["hypervisor"]

              Chef::Log.info "IP: #{ip}, Action: #{attribute["rfcAction"]}, hypervisor: #{hypervisor}"

              if attribute["rfcAction"].eql? "replace"
                @public_remove_ips.push(ip)
                @public_ips.delete(ip)
                Chef::Log.info "Ip to remove: #{ip}"
              end
            end
          }
        end
      end

      def get_admin_credentials

        if (@public_ips.length > 0)
          get_credentials_from_diagnostic_cache(@public_ips.first)
          @couchbase_cli=Couchbase::CouchbaseCLI.new(@public_ips.first, @admin_username, @admin_password)
        end

      end

      def get_credentials_from_diagnostic_cache(ip)

        dir="/etc/nagios/conf.d"
        filename_cb_admin=execute_ssh_command(@public_ips.first, "sudo ls #{dir} | grep admin-console.cfg")
        filename_cb_admin=filename_cb_admin.chomp
        filename_cb_admin="#{dir}/#{filename_cb_admin}"
        command = "sudo less #{filename_cb_admin} | grep check_command | awk '{print $2}' | cut -d! -f4,5"
        Chef::Log::info "Cmd: #{command}"
        result=execute_ssh_command(@public_ips.first, command)

        if result == nil || result.to_s.empty?
          Chef::Application.fatal!("Couchbase_cli: Unable to get couchbase admin credentials!")
        end

        data=result.split('!')

        @admin_username=data[0].chomp
        @admin_password=data[1].chomp

      end

      def create_ssh_key

        if workorder.payLoad.has_key?("SecuredBy")
          ssh_key=workorder.payLoad["SecuredBy"][0][:ciAttributes][:private]


          puuid = (0..32).to_a.map { |a| rand(32).to_s(32) }.join
          @ssh_key_file = "/tmp/"+puuid

          out_file = File.new(ssh_key_file, "w")
          out_file.puts(ssh_key)
          out_file.close

          File.chmod(0600, @ssh_key_file)
        end

      end

      def delete_ssh_file

        File.delete(ssh_key_file)

      end
    end
  end
end
