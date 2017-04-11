module Nodetool
	module Util
		def self.info_command?(command)
				return command !~ /status|info/
		end
		def self.sudo_user?(user)
				`ls /etc/sudoers.d | sort> /tmp/sudo.out`
				found = `grep #{user} /tmp/sudo.out |  wc -l`
				return found.to_i > 0
		end
		def self.command_restricted?(command)
			restricted_commands = []
			restricted_commands.push("compact","decommission","disableautocompaction","disablebackup")
			restricted_commands.push("disablebinary","disablegossip","disablehandoff","disablethrift")
			restricted_commands.push("drain","enableautocompaction","enablebackup","enablebinary","enablegossip")
			restricted_commands.push("enablehandoff","enablethrift","invalidatekeycache","invalidaterowcache","join")
			restricted_commands.push("move","pausehandoff","proxyhistograms","rangekeysample","rebuild")
			restricted_commands.push("rebuild_index","refresh","removenode","resetlocalschema")
			restricted_commands.push("resumehandoff","scrub","setcachecapacity","setcachekeystosave","setcompactionthreshold")
			restricted_commands.push("setcompactionthroughput","sethintedhandoffthrottlekb","setstreamthroughput")
			restricted_commands.push("settraceprobability","snapshot","stopdaemon","taketoken","truncatehints")
			command.split(" ").each do |cmd|
				if restricted_commands.include?(cmd.downcase)
					return true
				end
			end
			return false
		end
		def self.has_permission?(user, nodetool_command)
			if !info_command?(nodetool_command)
				return true
			end
			if sudo_user?(user)
				return true
			end
			return !command_restricted?(nodetool_command)
		end
		def self.nodetool_command_running?
			cmd = `ps -eaf | grep NodeTool | grep -v grep | wc -l`
			return cmd.to_i > 0? true : false
		end
		def self.validate(user, nodetool_command)
			if nodetool_command =~ /-h/
			   puts "***FAULT:FATAL=Nodetool command with host option is not supported"
			   e = Exception.new("no backtrace")
			   e.set_backtrace("")
			   raise e
		   end
		
			if nodetool_command =~ /repair/ and nodetool_command !~ /-pr/
				puts "***FAULT:FATAL=Nodetool repair without -pr is not supported"
			   e = Exception.new("no backtrace")
			   e.set_backtrace("")
			   raise e
			end
		
			if !has_permission?(user, nodetool_command)
				puts "***FAULT:FATAL=Nodetool option #{nodetool_command} is blocked as no sudo permissions"
			   e = Exception.new("no backtrace")
			   e.set_backtrace("")
			   raise e
			end
		
			if nodetool_command_running?
			   puts "***FAULT:FATAL=Nodetool operation already running, please try after they finished."
			   e = Exception.new("no backtrace")
			   e.set_backtrace("")
			   raise e
			end
		end
	end
end

  

