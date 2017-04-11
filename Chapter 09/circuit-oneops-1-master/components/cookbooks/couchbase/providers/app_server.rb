##
# app_server providers
#
# Installs couchbase server
#
# @Author Alex Natale <anatale@walmartlabs.com>
##

def whyrun_supported?
  true
end

use_inline_resources

##
# Get the Couchbase installer package details. In order to get the base_url, try component mirrors
# first, if empty try cloud mirrors, if empty use cookbook mirror (src_mirror) attribute.
#
# @return 3-tuple consists of (download_url, package_type, package_installer)
##

def getPackageDetails(cloud_name, cookbook_name, a_comp_mirrors, a_cloud_mirrors, src_mirror, node_platform, distributionurl)

  #Chef::Log.info("Getting mirror for app: #{cookbook_name} & cloud: #{cloud_name}")
  base_url = ''
  base_url = distributionurl if (distributionurl != nil && !distributionurl.empty?)

  log "getting_couchbase_pack" do
    message "Getting mirror for app: #{cookbook_name},  cloud: #{cloud_name} base url: #{base_url}"
    level :info
  end

  # Search for component mirror
  comp_mirrors = JSON.parse(a_comp_mirrors) if base_url.empty?
  base_url = comp_mirrors[0] if (comp_mirrors != nil && comp_mirrors.size > 0)
  # Search for cloud mirror
  cloud_mirrors = JSON.parse(a_cloud_mirrors) if base_url.empty?
  base_url = cloud_mirrors[cookbook_name] if !cloud_mirrors.nil? && cloud_mirrors.has_key?(cookbook_name)
  # Search for cookbook default attribute mirror
  base_url = src_mirror if base_url.empty?

  case node_platform
    # Redhat based distros
    when 'redhat', 'centos', 'fedora'
      package_type = 'rpm'
      package_installer = 'rpm -i --nodeps'
      yum_package 'perl-Time-HiRes' do
        action :install
      end
    # Debian based ditros
    when 'ubuntu', 'debian'
      package_type = 'deb'
      package_installer = 'dpkg -i'
    else
      Chef::Application.fatal!("#{node_platform} platform is not supported for Couchbase.")
  end
  #Chef::Log.info("Mirror base_url: #{base_url} & package_type: #{package_type}")
  log "result_couchbase_pack" do
    message "Mirror base_url: #{base_url} & package_type: #{package_type}"
    level :info
  end
  return base_url, package_type, package_installer
end



action :prerequisites do
  #Chef::Log.info("App Server::Pre-requisites")

  #Kernel Tunings -- Setting Swapiness to 0
  sysctl_file = '/etc/sysctl.conf'
  `grep swappiness #{sysctl_file}`
  if $?.to_i != 0
    `echo 0 > /proc/sys/vm/swappiness`
    `echo "#Set swappiness to 0 to avoid swapping" >> #{sysctl_file}`
    `echo "vm.swappiness = 0" >> #{sysctl_file}`
  end

#Kernel Tunings -- Disable THP
  rc_file = '/etc/rc.local'
  `grep transparent_hugepage #{rc_file}`
  if $?.to_i != 0
    `echo "#Disabling THP" >> #{rc_file}`
    `echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
 echo never > /sys/kernel/mm/transparent_hugepage/enabled
 fi
 if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
 echo never > /sys/kernel/mm/transparent_hugepage/defrag
 fi
 if test -f /sys/kernel/mm/redhat_transparent_hugepage/defrag; then
 echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag
 fi
 if test -f /sys/kernel/mm/redhat_transparent_hugepage/enabled; then
 echo never > /sys/kernel/mm/redhat_transparent_hugepage/enabled
fi" >> #{rc_file}`
    execute "/etc/rc.local"
  end

end

action :download_install_couchbase do
  #Chef::Log.info("====> couchbase-server-#{new_resource.version}")
  log "download_couchbase_pack" do
    message "Searching pack: couchbase-server-#{new_resource.version}"
    level :info
  end
# Query package details
  arch = new_resource.arch
  version = new_resource.version
  base_url, pkg_type, pkg_installer = getPackageDetails(new_resource.cloud_name, new_resource.cookbook_name, new_resource.comp_mirrors, new_resource.cloud_mirrors, new_resource.src_mirror, new_resource.node_platform, new_resource.distributionurl)
  if (base_url.include? "couchbase.com") && (version.include? "3.")
    arch = "centos6."+new_resource.arch
  end

  if ('community' == new_resource.edition)
      base_url = base_url.gsub('couchbase-server-enterprise', 'couchbase-server-community')
  end

  pkg = PackageFinder.search_for(base_url, "couchbase-server-#{new_resource.edition}", new_resource.version, arch, pkg_type)


# Get the url and filename from the package.
  if pkg.empty?
    Chef::Application.fatal!("Can't find the install package.")
  end
  url = pkg[0]
  file_name = pkg[1]
  dl_file = ::File.join(Chef::Config[:file_cache_path], '/', file_name)

# Download the package
  remote_file dl_file do
    source url
    checksum new_resource.sha256 if !new_resource.sha256.empty?
    action :create_if_missing
  end

  couchbase_installed = `sudo rpm -qa | grep couchbase-server |  cut -d- -f1-3`
  couchbase_installed = couchbase_installed.strip!

  version_installed = `sudo rpm -qa | grep couchbase-server |  cut -d- -f3-3`
  version_installed = version_installed.strip!

  #Chef::Log.info("#{couchbase_installed} couchbase-server-#{new_resource.version}")
  log "Checking_couchbase_pack_installed_vs_selected" do
    message "Couchbase Server version installed: #{couchbase_installed} vs: couchbase-server-#{new_resource.version}"
    level :info
  end

  if couchbase_installed != nil

    edition_installed = `egrep license /opt/couchbase/etc/runtime.ini`
    
    if edition_installed == nil || edition_installed.index('=') == nil
      Chef::Application.fatal!("Unable to determine installed couchbase edition. Please correct license entry in /opt/couchbase/etc/runtime.ini")
    end
    
    edition_installed = edition_installed[edition_installed.index('=') + 1 .. edition_installed.length].strip

    if new_resource.edition != edition_installed
      msg = "Incompatible versions detected: Couchbase installed edition is #{edition_installed} whereas the binary being installed is #{new_resource.edition}"
      #Chef::Application.fatal!("#{msg}")
      puts "***FAULT:FATAL="+msg
      Chef::Log.error("#{msg}")
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end

  end

  if couchbase_installed == nil && new_resource.version == "2.2.0" && new_resource.replace_node == nil
    msg = "Couchbase Server #{new_resource.version} has been deprecated. Upgrade to the latest Couchbase server version. More info https://confluence.walmart.com/display/PGPCACHEAAS/Upgrading+Couchbase+using+OneOps"
    Chef::Application.fatal!("#{msg}")
  end

  if couchbase_installed == "couchbase-server-#{new_resource.version}" || couchbase_installed == nil
    log "installing_couchbase" do
      message "Installing couchbase-server-#{new_resource.version}"
      level :info
    end
    #Chef::Log.info("Couchbase Server version installed: #{couchbase_installed} vs: couchbase-server-#{new_resource.version}")
    #Chef::Log.info("Source: #{dl_file} Package Type: #{pkg_type} Upgrade: #{new_resource.upgradecouchbase}")

    # Install the package
    package "couchbase-server-#{new_resource.version}" do
      source dl_file
      provider Chef::Provider::Package::Rpm if pkg_type == 'rpm'
      provider Chef::Provider::Package::Dpkg if pkg_type == 'deb'
      action :install
    end
  elsif  new_resource.upgradecouchbase == 'true' && new_resource.version > version_installed
    #Chef::Log.info("Performing Upgrade: #{new_resource.upgradecouchbase}")
    log "upgrading_couchbase" do
      message "Performing Upgrade: #{new_resource.upgradecouchbase} from  #{couchbase_installed} to couchbase-server-#{new_resource.version}"
      level :info
    end
    #stop couchbase server if running
    service "couchbase-server" do
      action :stop
    end
    # Upgrade the package
    case pkg_type
      when 'rpm'
        rpm_package "couchbase-server-#{new_resource.version}" do
          action :install
          source dl_file
          options "--replacepkgs"
        end
      when 'deb'
        dpkg_package  "couchbase-server-#{new_resource.version}" do
          source dl_file
          action :install
          option "--force-all"
        end
    end
  else
    msg = "Selected Couchbase Server version:#{new_resource.version} doesn't match installed version:#{couchbase_installed}!"
    Chef::Application.fatal!("#{msg}")
  end
end
