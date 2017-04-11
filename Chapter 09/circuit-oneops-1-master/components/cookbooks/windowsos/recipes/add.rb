Chef::Log.info("Executing WindowsOS::Add recipe ...")

Chef::Log.info("running install_packages")
include_recipe "windowsos::install_packages"

Chef::Log.info("running os::time")
include_recipe "os::time"
