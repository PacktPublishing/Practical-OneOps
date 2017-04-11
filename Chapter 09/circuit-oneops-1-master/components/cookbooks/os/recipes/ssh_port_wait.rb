# wait for ssh to be open
require 'socket'
require 'timeout'
port_closed = true
retry_count = 0
ruby_block 'ssh port wait' do
  block do

    if node.ip.nil?
      puts "***FAULT:FATAL=ip missing"
      Chef::Log.error("no ip")
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end

   if node.has_key?('max_retry_count_add')
      max_retry_count = node.max_retry_count_add
    else
      max_retry_count = 10
    end

    ip = node.ip
    port = 22
    if node.ip.include?(":")
      parts = node.ip.split(":")
      ip = parts.first
      port = parts.last
    end

    while port_closed && retry_count < max_retry_count do
      begin
        Timeout::timeout(5) do
          begin
            TCPSocket.new(ip, port).close
            port_closed = false
            Chef::Log.info("ssh port open")
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          end
        end
      rescue Timeout::Error
      end
      if port_closed
        Chef::Log.info("waiting for ssh port #{ip}:#{port} 10sec ")
        sleep 5
      end
      retry_count += 1
    end
    Chef::Log.info("ssh port closed") if port_closed

    node.set[:ssh_port_closed] = port_closed

  end
end
