cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub("cloud.service.","").downcase

_hosts = node.workorder.rfcCi.ciAttributes.has_key?('hosts') ? JSON.parse(node.workorder.rfcCi.ciAttributes.hosts) : {}
_hosts.values.each do |ip|
  if ip !~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/
    Chef::Log.error("host value of: \"#{ip}\" is not an ip.  fix hosts map to have hostname then ip in the 2 fields.")

    puts "***FAULT:FATAL=invalid host ip #{ip} - check hosts attribute"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e

  end
end

full_hostname = node[:full_hostname]
_hosts[full_hostname] = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["private_ip"]

execute("mkdir -p /etc/cloud")

bash "set-hostname" do
  code <<-EOH
  hostnamectl set-hostname #{node.vmhostname}
  printf "hostname: #{node.vmhostname}\nfqdn: #{full_hostname}\n" > /etc/cloud/cloud.cfg.d/99_hostname.cfg
  if grep -Fxq "preserve_hostname: true" /etc/cloud/cloud.cfg
  then
    echo "preserver hostname already set to true in /etc/cloud/cloud.cfg"
  else
    printf "preserve_hostname: true\n" >> /etc/cloud/cloud.cfg
  fi
EOH
  not_if { provider.include? "docker" }
end

# update /etc/hosts
gem_package "ghost"

file "/tmp/hosts" do
  owner 'root'
  group 'root'
  mode 0755
  content _hosts.map {|e| e.join(" ") }.join("\n")
  action :create
end

bash "update_hosts" do
  code <<-EOH
    ghost empty
    ghost import /tmp/hosts
  EOH
end


# add short hostname at the end of the FQDN entry line in /etc/hosts
ruby_block 'update /etc/hosts' do
  block do
    tmp_host = File.read("/etc/hosts")
    mod_host = tmp_host.gsub(full_hostname,full_hostname+" "+node.vmhostname)
    File.open("/tmp/etc_hosts", "w") do |file|
        file.puts mod_host
    end
    `cat /tmp/etc_hosts > /etc/hosts`
 end
end

# bind install
bind_package_name = value_for_platform(
  [ "debian","ubuntu" ] => {"default" => "bind9"},
  ["fedora","redhat","centos","suse"] => {"default" => "bind" },
  "default" => "named"
)

package bind_package_name do
    action :install
end

# redhad package is bind but the service resource next uses named
bind_package_name = value_for_platform(
  [ "debian","ubuntu" ] => {"default" => "bind9"},
  "default" => "named"
)


customer_domain = node["customer_domain"]
if customer_domain =~ /^\./
  customer_domain.slice!(0)
end

Chef::Log.info("adding /opt/oneops/domain... ")
`echo #{customer_domain} > /opt/oneops/domain`

ruby_block 'setup bind and dhclient' do
  block do

    Chef::Log.info("*** SETUP BIND ***")

    given_nameserver =(`cat /etc/resolv.conf |grep -v 127  | grep -v '^#' | grep nameserver | awk '{print $2}'`.split("\n")).join(";")
    if given_nameserver.empty?
      given_nameserver = '8.8.4.4'
      `echo "nameserver #{given_nameserver}" > /etc/resolv.conf`
    end
    Chef::Log.info("nameservers: #{given_nameserver}")

    node.customer_domain
    zone_domain = node.customer_domain.downcase
    dns_zone_found = false
    while !dns_zone_found && zone_domain.split(".").size > 2
      result = `dig +short NS #{zone_domain}`.to_s
      valid_result = result.split("\n") - [""]
      if valid_result.size > 0
        puts "found: #{zone_domain}"
        dns_zone_found = true
      else
        parts = zone_domain.split(".")
        trash = parts.shift
        zone_domain = parts.join(".")
      end

    end
    Chef::Log.info("dns zone domain: "+zone_domain)

    zone_config = ""

    case node.platform
    when "redhat","centos"
      named_conf = 'include "/etc/bind/named.conf.options";'+"\n"
      # commented out to prevent adding authoritative servers for the zone
      # named_conf += 'include "/etc/bind/named.conf.local";'+"\n"
      ::File.open("/etc/named.conf", 'w') {|f| f.write(named_conf) }
      `mkdir -p /etc/bind/`
      `mkdir -p /var/cache/bind`
    end

    options_config =  "options {\n"
    options_config += "  directory \"/var/cache/bind\";\n";
    options_config += "  auth-nxdomain no;    # conform to RFC1035\n";
    options_config += "  listen-on-v6 { any; };\n";
    options_config += "  forward only;\n"
    options_config += "  forwarders { "+given_nameserver+"; };\n"
    options_config += "};\n"

    named_options_file = "/etc/bind/named.conf.options"
    named_options_file = "/etc/named.d/named.conf.options" if node.platform == "suse"
    ::File.open(named_options_file, 'w') {|f| f.write(options_config) }

    if node.platform != "ubuntu"
      bind_option = "OPTIONS=\"-4\""
        ::File.open("/etc/sysconfig/named", 'w') {|f| f.write(bind_option) }
    end

    authoritative_dns_servers = (`dig +short NS #{zone_domain}`).split("\n")
    puts "authoritative_dns_servers: "+authoritative_dns_servers.join(" ")
    dig_out = `dig +short #{authoritative_dns_servers.join(" ")}`
    nameservers = dig_out.split("\n")

    zone_config += "zone \"#{zone_domain+'.'}\" IN {\n"
    zone_config += "    type forward;\n"
    zone_config += "    forwarders {"+nameservers.join(";")+";};\n"
    zone_config += "};\n"

    named_conf_local_file = "/etc/bind/named.conf.local"
    named_conf_local_file = "/etc/named.d/named.conf.local" if node.platform == "suse"
    ::File.open(named_conf_local_file, 'w') {|f| f.write(zone_config) }


    # allow additional search domains to take priority over customer-env-cloud domain
    customer_domains = ""
    customer_domains_dot_terminated = ""
    if node.workorder.rfcCi[:ciAttributes].has_key?("additional_search_domains") &&
      !node.workorder.rfcCi.ciAttributes.additional_search_domains.empty?

      additional_search_domains = JSON.parse(node.workorder.rfcCi.ciAttributes.additional_search_domains)
      additional_search_domains.each do |d|
        customer_domains += "\"#{d.strip}\","
        customer_domains_dot_terminated += "#{d.strip}. "
      end
    end
    customer_domains += "\"#{customer_domain}\""
    customer_domains.downcase!
    customer_domains_dot_terminated += "#{customer_domain}."
    customer_domains_dot_terminated.downcase!

    Chef::Log.info("supersede domain-search #{customer_domains}")
    dhcp_config_content = "supersede domain-search #{customer_domains};\n"
    dhcp_config_content += "prepend domain-name-servers 127.0.0.1;\n"
    dhcp_config_content += "supersede domain-name-servers #{given_nameserver.gsub(";",",")};\n"
    dhcp_config_content += "send host-name \"#{full_hostname}\";\n"

    dhcp_config_file = "/etc/dhcp/dhclient.conf"
    Chef::Log.info("writing dhcp config: #{dhcp_config_file}")
    ::File.open(dhcp_config_file, 'w') {|f| f.write(dhcp_config_content) }


    # handle other config files such as /etc/dhcp/dhclient-eth0.conf
    # these shall be linked to dhclient.conf
    Chef::Log.info("symlink any dhclient-* files to dhclient.conf...")
    other_dhclient_files = `ls -1 /etc/dhcp/*conf|grep -v dhclient.conf`.split("\n")
    other_dhclient_files.each do |file|
       Chef::Log.info("linking #{file}")
       `rm -f #{file}`
      `ln -sf /etc/dhcp/dhclient.conf #{file}`
    end

    dhclient_kill_service="killdhclient"
    dhclient_kill_script = "/etc/init.d/#{dhclient_kill_service}"

    # attribute dhclient will be false if the compute is to use the more static approach to ip address. we are to eliminate dhclient process
    attrs = node[:workorder][:rfcCi][:ciAttributes]
    if attrs[:dhclient] == 'false' && node.platform != "ubuntu"
        # prepend to the /etc/resolv.conf file as well
        Chef::Log.info("adjusting resolv.conf because dhclient not desired")
        Chef::Log.info("resolv search #{customer_domains_dot_terminated}")
        `cp -f /etc/resolv.conf /etc/resolv.conf.orig ; true`
        ## note- further nameserver entries will already be in the file at this point
        `echo '; gen by remote.rb' > /etc/resolv.conf.mod ; true`
        `echo 'search #{customer_domains_dot_terminated}' >> /etc/resolv.conf.mod ; true`
        # skip caching dns for containers
        `echo 'nameserver 127.0.0.1' >> /etc/resolv.conf.mod ; true` unless ['docker'].index(provider)
        `echo '#_' >> /etc/resolv.conf.mod ; true`
        `grep nameserver /etc/resolv.conf.orig | grep -v 127.0.0.1 >> /etc/resolv.conf.mod; true`
        `cp -f /etc/resolv.conf.mod /etc/resolv.conf.mod2 ; true`
        `cat /etc/resolv.conf.mod > /etc/resolv.conf ; true`

        # leave behind a script that will stop dhclient for after reboots
        if !File.exists?("#{dhclient_kill_script}")
           Chef::Log.info("writing executable script #{dhclient_kill_script} to kill dhclient because dhclient not desired")
           `echo '#!/bin/sh' > #{dhclient_kill_script} ; true`

            #`echo '# #{dhclient_kill_script} kills dhclient' >> #{dhclient_kill_script} ; true`
           #start=run level 23  start-priority=17
           `echo '# chkconfig:   23 17 17' >> #{dhclient_kill_script} ; true`
           `echo '# description: kills the dhclient' >> #{dhclient_kill_script} ; true`
           `echo '### BEGIN INIT INFO' >> #{dhclient_kill_script} ; true`
           `echo '# Provides: dhclient kill' >> #{dhclient_kill_script} ; true`
           `echo '# Required-Start: $network' >> #{dhclient_kill_script} ; true`
           `echo '### END INIT INFO' >> #{dhclient_kill_script} ; true`
           `echo '##generated by remote.rb' >> #{dhclient_kill_script} ; true`

           `echo 'start() {' >> #{dhclient_kill_script} ; true`
           `echo 'sleep 10' >> #{dhclient_kill_script} ; true`
           `echo 'ps -ef|grep -v grep|grep dhclient > /var/log/dhclient_kill.log' >> #{dhclient_kill_script} ; true`
           `echo 'pkill -f dhclient' >> #{dhclient_kill_script} ; true`
           `echo 'RETVAL=$?' >> #{dhclient_kill_script} ; true`
           `echo 'echo $RETVAL >> /var/log/dhclient_kill.log' >> #{dhclient_kill_script} ; true`
           `echo '}' >> #{dhclient_kill_script} ; true`
           `echo 'stop() {' >> #{dhclient_kill_script} ; true`
           `echo ' :' >> #{dhclient_kill_script} ; true`
           `echo '}' >> #{dhclient_kill_script} ; true`
           `echo '# See how we were called.' >> #{dhclient_kill_script} ; true`
           `echo 'case "$1" in' >> #{dhclient_kill_script} ; true`
           `echo ' start)' >> #{dhclient_kill_script} ; true`
           `echo '   start' >> #{dhclient_kill_script} ; true`
           `echo '   ;;' >> #{dhclient_kill_script} ; true`
           `echo ' stop)' >> #{dhclient_kill_script} ; true`
           `echo '   stop' >> #{dhclient_kill_script} ; true`
           `echo '   ;;' >> #{dhclient_kill_script} ; true`
           `echo ' *)' >> #{dhclient_kill_script} ; true`
           `echo '   echo "Usage: $0 {start|stop}"' >> #{dhclient_kill_script} ; true`
           `echo '   exit 2' >> #{dhclient_kill_script} ; true`
           `echo 'esac' >> #{dhclient_kill_script} ; true`
           `chmod +x #{dhclient_kill_script}`
        end
        `chkconfig --add #{dhclient_kill_service}`
    elsif node.platform != "ubuntu"
        # remove the script that stops dhclient. it might not be there - it is ok
        `chkconfig --list #{dhclient_kill_service}`
        if $?.to_i == 0
            Chef::Log.info("removing script that kills dhclient - #{dhclient_kill_script} - dhclient is desired if we boot")
            `chkconfig --del #{dhclient_kill_service}`
        else
            Chef::Log.info("no need to remove script that kills dhclient - it was not here")
        end
    end

    dhclient_cmdline = "/sbin/dhclient"
  
    # try to use options that its running with
    dhclient_ps = `ps auxwww|grep -v grep|grep dhclient`
    if dhclient_ps.to_s =~ /.*:\d{2} (.*dhclient.*)/
        dhclient_cmdline = $1
    end    
    
    # always kill
   `pkill -f dhclient`

    # prevent dhcp from overwriting /etc/resolv.conf
    if node.platform == "ubuntu"
      `resolvconf --disable-updates`
    end

    # but restart (and leave running) if dhclient is choice selected. and leave it down otherwise
    if attrs[:dhclient] == 'true'
      Chef::Log.info("starting: #{dhclient_cmdline}")
      output = `#{dhclient_cmdline}`
      Chef::Log.info("returned: #{output} exitstatus: #{$?.exitstatus}")

    else
       Chef::Log.info("will not start dhclient because dhclient not desired")
    end

  end
end


service bind_package_name do
  supports :restart => true
  action [:enable, :restart]
end


# DHCLIENT

case node.platform
when "fedora","redhat","centos"
  file = "/etc/sysconfig/network-scripts/ifcfg-eth0"
  `grep PERSISTENT_DHCLIENT #{file}`
  if $?.to_i != 0
    Chef::Log.info("DHCLIENT setting ifcfg-eth0 - network restart")
    `echo "PERSISTENT_DHCLIENT=1" >> #{file} ; /sbin/service network restart`
  else
    Chef::Log.info("DHCLIENT already configured")
  end
end


ruby_block "printing hostname fqdn" do
  block do
    fqdn = `hostname -f`
    Chef::Log.info("Executing 'hostname -f' : #{fqdn}")
  end
end
