#
# Cookbook Name:: tomcat
# Recipe:: force-stop

bash "FORCE_STOP_TOMCAT" do

  code <<-EOH
        pid=$(pgrep -f "org.apache.catalina.startup.Bootstrap")
       if [ -n "$pid" ] ; then
               echo "Killing Tomcat of process $pid "
            kill -9 "$pid"
            sleep 5
            pid=$(pgrep -f "org.apache.catalina.startup.Bootstrap")
        if [ -n "$pid" ] ; then
              echo "Could not stop tomcat."
              exit 1
        else
              rm -f   "/var/lock/subsys/tomcat#{node[:tomcat][:version][0,1]}"
              rm -f   "#{node[:tomcat][:home]}/tomcat.pid"
              echo "Tomcat stopped"


        fi
        else
          echo "Tomcat not running"
      fi

  EOH
end

