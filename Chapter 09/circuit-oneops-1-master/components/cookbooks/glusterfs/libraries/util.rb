
def exit_with_error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end

def find_bricks(index,replicas,length)
  bricks = Array.new
  for n in 0..(replicas-1)
    brick_id = (index - 1) * replicas + 1 - n * (replicas - 1)
    brick_id = brick_id > 0 ? brick_id : brick_id + length * replicas
    bricks << brick_id
  end
  return bricks
end

def extract_hosts_from_bricks(bricks)
	hosts = Array.new
	bricks.each do |b|
		hosts << b.scan(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/).to_s
	end
	return hosts
end

def execute_command(command, exit_out = true)
	output = `#{command} 2>&1`
	if $?.success?
		Chef::Log.info("#{command} got successful. #{output}")
	else
		exit_with_error "#{command} got failed. #{output.gsub(/\n+/, '.')}" if exit_out
		Chef::Log.warn("#{command} got failed. #{output.gsub(/\n+/, '.')}") if !exit_out
	end
end
