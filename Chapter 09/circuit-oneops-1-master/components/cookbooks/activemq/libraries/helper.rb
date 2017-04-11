module Activemq
  # Helper module containing library functions.
  module Helper
    include Chef::Mixin::ShellOut
    # To decide access type based on profile.
    def self.encrypt(node, pwd, key, type)
       version = node['activemq']['version']
       activemq_home = "#{node['activemq']['installpath']}/apache-activemq-#{version}"
       cmd =  " export ACTIVEMQ_ENCRYPTION_PASSWORD=#{key}; cd #{activemq_home} ; java -cp './amq-messaging-resource.jar:*' io.strati.amq.MessagingResources -r encryptPwd -k #{key} -p #{pwd}"
       cmd_shellout = Mixlib::ShellOut.new(cmd).run_command

       if cmd_shellout.stdout.include? "Error"
         message = "Unable to encrypt the password."
         Chef::Log.fatal("***** FATAL *****" +message)
       else
         encpwd = cmd_shellout.stdout.split(" - ").last.to_s
         encpwd.gsub!("\n", "")
         if type == 'adminencpwd'
            node.set[:activemq][:adminencpwd] = "ENC(#{encpwd})"
         elsif type == 'brokerencpwd'
            node.set[:activemq][:brokerencpwd] = "ENC(#{encpwd})"
         else
             node.set[:activemq][:encpwd] = encpwd
         end
         return encpwd
       end
    end

    def self.getencpasswordkey(node)

      assembly = node[:workorder][:payLoad][:Assembly][0][:ciName]
      env =  node[:workorder][:payLoad][:Environment][0][:ciName]

        return assembly+env[0...2]
   end
  end
end
