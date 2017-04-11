module OOLog
  def fatal(msg)
    Chef::Log.error(msg)
    puts "***FAULT:FATAL=#{msg}"
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e
  end

  def info(msg)
    Chef::Log.info(msg)
  end

  def debug(msg)
    Chef::Log.debug(msg)
  end

  module_function :fatal, :info, :debug
end
