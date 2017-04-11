module Couchbase
  class RemoteSsh
    attr_accessor :workorder, :ssh_key_file

    def initialize(workorder)
      @workorder=workorder
    end

    def execute_ssh_command(host, command)

      create_ssh_key
      command="ssh -i #{@ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{host} #{command}"
      result = %x[ #{command} ]
      delete_ssh_file

      result

    end

    def create_ssh_key

      if !workorder.payLoad.has_key?("SecuredBy")
        raise "Unable to create ssh key"
      end

      ssh_key=workorder.payLoad["SecuredBy"][0][:ciAttributes][:private]

      puuid = (0..32).to_a.map { |a| rand(32).to_s(32) }.join
      @ssh_key_file = "/tmp/"+puuid

      out_file = File.new(ssh_key_file, "w")
      out_file.puts(ssh_key)
      out_file.close

      File.chmod(0600, @ssh_key_file)
    end

    def delete_ssh_file

      File.delete(ssh_key_file)

    end
  end
end
