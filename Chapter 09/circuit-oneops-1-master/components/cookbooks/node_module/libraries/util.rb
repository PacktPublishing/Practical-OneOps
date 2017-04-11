# Exit the chef application process with the given error message
#
# @param : msg -  Error message
#
def exit_with_error(msg)
	Chef::Log.error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end
