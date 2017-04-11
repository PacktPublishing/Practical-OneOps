include_pack "generic_ring"

name "graphite"
description "Graphite"
type "Platform"
category "Monitoring"

platform :attributes => {
	  'autoreplace' => 'false'
}

resource 'secgroup',
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0","2004 2004 tcp 0.0.0.0/0","2003 2003 tcp 0.0.0.0/0","11211 11211 tcp 0.0.0.0/0","2104 2104 tcp 0.0.0.0/0","2103 2103 tcp 0.0.0.0/0", "2023 2023 tcp 0.0.0.0/0","2024 2024 tcp 0.0.0.0/0","2003 2003 udp 0.0.0.0/0","2004 2004 udp 0.0.0.0/0","2103 2103 udp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource 'compute',
         :attributes => {"size" => "S"}

resource 'os',
	 :cookbook => 'oneops.1.os',
	 :design => true,
	 :attributes => {
	     :ostype => 'centos-7.2', 
	     :sysctl  => '{"net.ipv4.tcp_mem":"3064416 4085888 6128832", "net.ipv4.tcp_rmem":"4096 1048576 16777216", "net.ipv4.tcp_wmem":"4096 1048576 16777216", "net.core.rmem_max":"16777216", "net.core.wmem_max":"16777216", "net.core.rmem_default":"1048576", "net.core.wmem_default":"1048576", "fs.file-max":"1048576", "net.core.somaxconn":"65535", "net.ipv4.tcp_max_syn_backlog":"8192", "net.core.netdev_max_backlog":"65536"}'
         }

resource "graphite",
         :cookbook => "oneops.1.graphite",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "dns"},
         :attributes => {
             },
          :monitors => {
             'graphiteprocess' => {:description => 'GraphiteProcess',
                :source => '',
                :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                :cmd => 'check_process!graphite!true!carbon',
                :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                :metrics => {
                    'up' => metric(:unit => '%', :description => 'Percent Up'),
                },
                :thresholds => {
                    'GraphiteProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 90, 1, 1), reset('>', 95, 1, 1))
                }
             },
             'memcachedprocess' => {:description => 'MemcachedProcess',
                 :source => '',
                 :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                 :cmd => 'check_process!memcached!true!memcached',
                 :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                 :metrics => {
                     'up' => metric(:unit => '%', :description => 'Percent Up'),
                 },
                 :thresholds => {
                     'MemcachedProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 90, 1, 1), reset('>', 95, 1, 1))
                 }
             }
          }

resource "user-graphite",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "graphite",
             "description" => "App User",
             "home_directory" => "/home/graphite",
             "system_account" => true,
             "sudoer" => true
         }

# depends_on
[
  {:from => 'user-graphite', :to => 'compute'},
  {:from => 'graphite', :to => 'volume'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "ring::depends_on::graphite",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'graphite',
    :attributes    => { "flex" => true, "min" => 3, "max" => 10 }

# managed_via
[ 'graphite'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

# managed_via
['user-graphite', 'graphite'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
