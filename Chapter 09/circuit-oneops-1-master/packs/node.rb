include_pack "genericlb"
name "node"
description "Node.Js with NPMe"
type "Platform"
category "Others"

#environment "ha", {}

#The deployment context which application teams can set
resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
           "inbound" => '[ "22 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0","8443 8443 tcp 0.0.0.0/0"]'
         },
         :requires => {
           :constraint => "1..1",
           :services => "compute"
         }

resource "user-app",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
           "username" => "app",
           "description" => "App User",
           "home_directory" => "/home/app",
           "system_account" => true,
           "sudoer" => true
         }

resource "nodejs",
         :cookbook => "oneops.1.node",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "*mirror",
           :help => "nodejs programming language environment"
         },
         :attributes => {
           :install_method => 'binary',
           :version => '4.4.7',
           :src_url => 'https://nodejs.org/dist/',
           :checksum_linux_x64 => '',
           :dir => '/usr/local',
           :npm_src_url => 'https://registry.npmjs.org/',
           :npm => '3.10.3'
         },
         :monitors => {
           'URL' => {
             :description => 'URL',
             :source => '',
             :enable => 'false',
             :chart => {'min' => 0, 'unit' => ''},
             :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
             :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
             :cmd_options => {
               'host' => 'localhost',
               'port' => '8080',
               'url' => '/',
               'wait' => '15',
               'expect' => '200 OK',
               'regex' => ''
             },
             :metrics => {
               'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
               'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false),
               'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE')
             },
             :thresholds => {

             }
           }
         }


resource "node-module",
         :cookbook => "oneops.1.node_module",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :help => "node module for nodejs"
         },
         :monitors => {
           'URL' => {
             :description => 'URL',
             :source => '',
             :chart => {'min' => 0, 'unit' => ''},
             :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
             :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
             :cmd_options => {
               'host' => 'localhost',
               'port' => '8080',
               'url' => '/',
               'wait' => '15',
               'expect' => '200 OK',
               'regex' => ''
             },
             :metrics => {
               'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
               'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false),
               'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE')
             },
             :thresholds => {

             }
           },

           'MemInfo' => {
             :description => 'MemInfo',
             :source => '',
             :chart => {'min' => 0, 'unit' => ''},
             :cmd => 'check_proc_mem!#{cmd_options[:warning]}!#{cmd_options[:critical]}!#{cmd_options[:pid]}',
             :cmd_line => '/opt/nagios/libexec/check_proc_mem -w $ARG1$ -c $ARG2$ --pid "$ARG3$"',
             :cmd_options => {
               'warning' => '1024',
               'critical' => '2048',
               'pid' => '`pgrep node`'
             },
             :metrics => {
               'RSS' => metric(:unit => 'B', :description => 'Resident memory', :dstype => 'GAUGE'),
               'HEAP' => metric(:unit => 'B', :description => 'Heap memory', :dstype => 'GAUGE', :display => false),
               'STACK' => metric(:unit => 'B', :description => 'Stack memory', :dstype => 'GAUGE')
             },
             :thresholds => {
               'CriticalMemory' => threshold('15m', 'avg', 'RSS', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
             }
           }
         }

resource "volume-log",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => { "constraint" => "1..1", "services" => "compute" },
         :attributes => {
           "mount_point"   => '/log',
           "size"          => '100%FREE',
           "device"        => '',
           "fstype"        => 'ext4',
           "options"       => ''
         },
         :monitors => {
           'usage' =>  {
             'description' => 'Usage',
             'chart' => {'min'=>0,'unit'=> 'Percent used'},
             'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
             'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
             'metrics' => {
               'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
               'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
             },
             :thresholds => {
               'LowDiskSpace' => threshold('1m','avg','space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
               'LowDiskInode' => threshold('1m','avg','inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
             },
           },
         }

resource "volume-app",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {
           "constraint" => "1..1",
           "services" => "compute"
         },
         :attributes => {
           "mount_point"   => '/app',
           "size"          => '50%FREE',
           "device"        => '',
           "fstype"        => 'ext4',
           "options"       => ''
         },
         :monitors => {
           'usage' =>  {
             'description' => 'Usage',
             'chart' => {'min'=>0,'unit'=> 'Percent used'},
             'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
             'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
             'metrics' => {
               'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
               'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used')
             },
             :thresholds => {
               'LowDiskSpace' => threshold('1m','avg','space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
               'LowDiskInode' => threshold('1m','avg','inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
             },
           }
         }

# depends_on
[
  {:from => 'os', :to => 'compute'},
  {:from => 'user-app', :to => 'os'},
  {:from => 'volume-app', :to => 'user-app'},
  {:from => 'volume-log', :to => 'volume-app'},
  {:from => 'nodejs', :to => 'user-app'},
  {:from => 'node-module', :to => 'nodejs'},
  {:from => 'node-module', :to => 'volume-log'},
  {:from => 'node-module', :to => 'user-app'},
  {:from => 'daemon', :to => 'node-module'},
  {:from => 'node-module', :to => 'volume-app'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# managed_via
['user-app', 'nodejs', 'node-module', 'volume-log', 'volume-app'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
