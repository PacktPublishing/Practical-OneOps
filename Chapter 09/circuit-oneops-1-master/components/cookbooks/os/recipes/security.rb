# SELINUX

case node.platform
when "fedora","redhat","centos"
  selinux_file = "/etc/selinux/config"
  `grep =disabled #{selinux_file}`
  if $?.to_i != 0
    selinux_conf = "SELINUX=disabled\n"
    selinux_conf += "SELINUXTYPE=targeted\n"
    ::File.open(selinux_file, 'w') {|f| f.write(selinux_conf) }
    `setenforce Permissive`
  else
    Chef::Log.info("SELINUX already disabled")
  end
end

# firewall

if node.platform_family == "rhel" && node.platform_version.to_i >= 7
  
  execute "systemctl mask firewalld ; systemctl stop firewalld"
  package "iptables-services"  
  
end

attrs = node[:workorder][:rfcCi][:ciAttributes]
if attrs[:iptables_enabled] == 'true'
  Chef::Log.info("firewall enabled")

  # cleanup
  execute "iptables -F"

  if attrs[:drop_policy] == 'true'
    simple_iptables_policy "INPUT" do
      policy "DROP"
    end
  end

  simple_iptables_rule "system" do
    rule "-m conntrack --ctstate ESTABLISHED,RELATED"
    jump "ACCEPT"
  end

  if attrs[:allow_loopback] == 'true'
    simple_iptables_rule "system" do
      rule "--in-interface lo"
      jump "ACCEPT"
    end
  end

  allow_rules = JSON.parse(attrs[:allow_rules])

  i = 1
  allow_rules.each do |rule|
    simple_iptables_rule "allow_rule_#{i}" do
      rule rule
      jump "ACCEPT"
    end
    i += 1
  end

  nat_rules = JSON.parse(attrs[:nat_rules])

  i = 1
  nat_rules.each do |rule|
    simple_iptables_rule "nat_rule_#{i}" do
      table "nat"
      direction "PREROUTING"
      rule rule
      jump false
    end
    i += 1
  end

  deny_rules = JSON.parse(attrs[:deny_rules])

  i = 1
  deny_rules.each do |rule|
    simple_iptables_rule "deny_rule_#{i}" do
      rule rule
      jump "DROP"
    end
    i += 1
  end


  include_recipe "simple_iptables::default"

  service "iptables" do
    action [ :restart, :enable ]
  end


else
  Chef::Log.info("firewall disabled")

  service "iptables" do
    action [ :stop, :disable ]
  end
end
