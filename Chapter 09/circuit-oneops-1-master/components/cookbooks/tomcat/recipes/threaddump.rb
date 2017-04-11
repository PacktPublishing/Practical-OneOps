proc_id= `pgrep -f "org.apache.catalina.startup.Bootstrap"`
proc_id=proc_id.chomp
tomcatuserid=`ps aux |grep java | grep -v grep  | awk '{print $1}'`
tomcatuserid=tomcatuserid.chomp
thread_dump_cmd="sudo -u  #{tomcatuserid} jstack -l #{proc_id}"
puts "Command is #{thread_dump_cmd}"
if !proc_id.empty?
  ruby_block "jstack_output" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
     cmdout =  shell_out!(thread_dump_cmd,
               :live_stream => Chef::Log::logger)
    end
  end
   if ($?.exitstatus).eql?(0)
    Chef::Log.info("Thread Dump Completed")
   else
    Chef::Log.error("Please ensure JDK is installed")
  end
else
  Chef::Log.error("Please ensure tomcat is running")
end
