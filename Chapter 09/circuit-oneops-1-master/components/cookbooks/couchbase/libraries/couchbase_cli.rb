module Couchbase
    class CouchbaseCLI

        @@cli='/opt/couchbase/bin/couchbase-cli'
        @ip
        attr_accessor :username, :password, :port_number

        def initialize(ip, username, password)
            @ip = ip
            @username = username
            @password = password
            @port_number="8091"
        end

        def list_nodes_command()
            build_command("server-list")
        end

        def list_nodes()
            execute_command(list_nodes_command)
        end

        def rebalance
            execute_command(build_command("rebalance"))
        end

        def rebalance_status
            execute_command(build_command("rebalance-status"))
        end

        def stop_rebalance
            execute_command(build_command("rebalance-stop"))
        end

        def add_node_command(ip)

            command = "rebalance"
            command += " --server-add=#{ip}:8091"
            command += " --server-add-username=\"#{@username}\""
            command += " --server-add-password=\"#{@password}\""

            build_command(command)

        end

        def add_node(ip)
            execute_command(add_node_command(ip))
        end

        def remove_nodes_command(ips)

            command = "rebalance"

            ips.each do |ip|
                command += " --server-remove=#{ip}:8091"
            end

            build_command(command)

        end

        def remove_nodes(ips)
            execute_command(remove_nodes(ips))
        end

        def fail_over_node_command(ip, force=false)

            command = "failover"
            command += " --server-failover=#{ip}:8091"

            if force
                command += " --force"
            end

            build_command(command)

        end

        def fail_over_nodes_command(ips, force=false)

            command = "failover"
            ips.each { |ip|
                command += " --server-failover=#{ip}:8091"
            }

            if (force)
                command += " --force"
            end

            build_command(command)

        end

        def fail_over_node(ip, force=false)
            execute_command(fail_over_node_command(ip, force))
        end

        def remove_node_command(ip)

            command = "rebalance"
            command += " --server-remove=#{ip}:8091"

            build_command(command)

        end

        def remove_node(ip)
            execute_command(remove_node_command(ip))
        end

        def list_buckets_command()
            build_command("bucket-list")
        end

        def list_buckets()
            execute_command(list_buckets_command)
        end

        def add_bucket_command(name, password, ramsize, replica)

            command = "bucket-create"
            command += " --bucket=\"#{name}\""
            command += " --bucket-type=couchbase"
            command += " --bucket-password=\"#{password}\""
            command += " --bucket-ramsize=#{ramsize}"
            command += " --bucket-replica=#{replica}"
            command += " --wait --force"

            build_command(command)

        end

        def add_bucket(name, password, ramsize, replica)
            execute_command(add_bucket_command(name, password, ramsize, replica))
        end

        def edit_bucket(name, password, ramsize, replica)

            command = "bucket-edit"
            command += " --bucket=\"#{name}\""
            command += " --bucket-password=\"#{password}\""
            command += " --bucket-ramsize=#{ramsize}"
            command += " --bucket-replica=#{replica}"
            command += " --wait --force"

            execute_command(build_command(command))

        end

        def remove_bucket_command(name, password)

            command = "bucket-delete"
            command += " --bucket=\"#{name}\""
            command += " --bucket-password=\"#{password}\""
            command += " --wait --force"

            build_command(command)

        end

        def remove_bucket(name, password)
            execute_command(remove_bucket_command(name, password))
        end

        def failover_node(ip)
            execute_command(build_command("failover --server-failover=#{ip}:8091"))
        end

        def readd_node(ip)

            command = "server-readd"
            command += " --server-add=#{ip}:8091"
            command += " --server-add-username=\"#{@username}\""
            command += " --server-add-password=\"#{@password}\""

            execute_command(build_command(command))

        end


        def readd_nodes(ips)

            command = "server-readd"

            ips.each { |ip|
                command += " --server-add=#{ip}:8091"
            }
            command += " --server-add-username=\"#{@username}\""
            command += " --server-add-password=\"#{@password}\""

            execute_command(build_command(command))

        end

        def autofailover_command(enabled, timeout)

            command = "setting-autofailover"
            command += " --enable-auto-failover=#{enabled ? 1 : 0}"
            command += " --auto-failover-timeout=#{timeout}"

            build_command(command)

        end

# This command does not work for version < 3.0 . rest api needs to be used to set autofailover setting
#        def autofailover(enabled, timeout)
#
#            execute_command(autofailover_command(enabled, timeout))
#
#        end

        def alerts(recipients, sender, user, password, host, port, enabled)

            command = "setting-alert"
            command += " --enable-email-alert=#{enabled ? 1 : 0}"
            command += " --email-recipients=#{recipients.join(",")}"
            command += " --email-sender=#{sender}"
            command += " --email-user=#{user}"
            command += " --email-password=#{password}"
            command += " --email-host=#{host}"
            command += " --email-port=#{port}"

            execute_command(build_command(command))

        end

        def init_cluster(username, password, ramsize, port)

            command = "cluster-init"
            command += " --cluster-username=\"#{username}\""
            command += " --cluster-password=\"#{password}\""
            command += " --cluster-port=#{port}"
            command += " --cluster-ramsize=#{ramsize}"

            execute_command(build_command(command))

        end

        def cluster_settings(ramsize)

            command = "cluster-init"
            command += " --cluster-username=\"#{username}\""
            command += " --cluster-password=\"#{password}\""
            command += " --cluster-port=#{port}"
            command += " --cluster-ramsize=#{ramsize}"

            execute_command(build_command(command))

        end

      def edit_cluster(username=nil, password=nil, ramsize=nil, port=nil)

          command = "cluster-edit"
          if username != nil
            command += " --cluster-username=\"#{username}\""
          end
          if password != nil
            command += " --cluster-password=\"#{password}\""
          end
          if ramsize != nil
            command += " --cluster-ramsize=#{ramsize}"
          end
          if port != nil
            command += " --cluster-port=#{port}"
          end
          execute_command(build_command(command))

      end

        def execute_command(command)

            result = %x(#{command})

            if result.include?("ERROR")
                raise result
            end

            return result

        end

        def build_command(action)

            command = "#{@@cli} "
            command += " #{action}"
            command += " -c #{@ip}:8091 "
            command += " -u \"#{@username}\""
            command += " -p \"#{@password}\""

            return command

        end

        private

    end
end
