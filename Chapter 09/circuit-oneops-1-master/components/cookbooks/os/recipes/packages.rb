# install base packages
["ntp", "which", "tar", "zip", "unzip", "bzip2", "sysstat",
  "autoconf", "automake", "libtool", "bison"].each do |pkg|

   if (node.platform == "centos" && node.platform_version == "5.8") &&
      ( pkg == "git" || pkg == "git-core" )
      
      Chef::Log.info("no git package on centos 5.8")
   elsif (node.platform == "suse" || node.platform == "ubuntu") && pkg == "which"
      Chef::Log.info("no which package on suse")
   elsif node.platform == "suse" && pkg == "nc"
      pkg = "netcat-openbsd"

   else
      package pkg do
          action :install
      end
   end
end

case node.platform
when "ubuntu"

  ["ca-certificates","python-software-properties"].each do |pkg|
    package pkg do
      action :install
    end
  end

when "suse"

  ["bind-utils","openssl"].each do |pkg|
    package pkg do
      action :install
    end
  end
  
else
  # redhat based
  nc = "nc"  
  if node.platform_version.to_i >= 7
    nc = "nmap-ncat"
  end
  ["bind-utils","openssl",nc].each do |pkg|
    package pkg do
      action :install
    end
  end

end
