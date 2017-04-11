
def execute_command(command)
	output = `#{command} 2>&1`
	Chef::Log.error "#{command} got failed. #{output.gsub(/\n+/, '.')}" unless $?.success?
end
