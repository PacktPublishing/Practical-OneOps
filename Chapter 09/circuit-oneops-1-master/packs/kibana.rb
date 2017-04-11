include_pack  "genericlb"
name          "kibana"
description   "Kibana"
type          "Platform"
category      "Search Engine"

platform :attributes => {'autoreplace' => 'false'}

environment "single", {}
environment "redundant", {}


resource 'compute',
         :cookbook => 'oneops.1.compute',
         :attributes => {'ostype' => 'default-cloud',
                         'size' => 'S'
         }

resource "lb",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
  :attributes => {
    "listeners" => '["http 5601 http 5601"]',
}

resource "user-app",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "app",
             "description" => "App User",
             "home_directory" => "/app",
             "system_account" => true,
             "sudoer" => true
         }

resource "kibana",
         :cookbook => "oneops.1.kibana",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "mirror"},
         :attributes => {
             'install_type' => 'binary',
             'src_url' => 'https://download.elastic.co/kibana/kibana',
             'install_path' => '/app/kibana',
             'version' => '4.1.2',
             'port' => '5601',
             'kibana_user' => 'app',
             'kibana_group' => 'app',
             'log_dir' =>'/log/kibana'
         }

configure_artifact_command=  <<-"EOF"
%w[ /log/kibana /log/logmon ].each do |path|
  directory path do
    owner 'app'
    group 'app'
  end
end
EOF

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "5601 5601 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "volume-log",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/log',
                         "size" => '100%FREE',
                         "device" => '',
                         "fstype" => 'ext4',
                         "options" => ''
         },
         :monitors => {
             'usage' => {'description' => 'Usage',
                         'chart' => {'min' => 0, 'unit' => 'Percent used'},
                         'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                       'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                         :thresholds => {
                          'LowDiskSpaceCritical' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                          'LowDiskInodeCritical' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                      },
             },
         }

resource "volume-app",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/app',
                         "size" => '5G',
                         "device" => '',
                         "fstype" => 'ext4',
                         "options" => ''
         },
         :monitors => {
             'usage' => {'description' => 'Usage',
                         'chart' => {'min' => 0, 'unit' => 'Percent used'},
                         'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                       'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                          :thresholds => {
                              'LowDiskSpaceCritical' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                              'LowDiskInodeCritical' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                            },
             }
         }

resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "0..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  }

# depends_on
[{:from => 'compute', :to => 'secgroup'},
 {:from => 'os', :to => 'compute'},
 {:from => 'user-app', :to => 'os'},
 {:from => 'user-app', :to => 'compute'},
 {:from => 'volume-app', :to => 'user-app'},
 {:from => 'volume-log', :to => 'volume-app'},
 {:from => 'kibana', :to => 'daemon'},
 {:from => 'kibana', :to => 'volume-log'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end


# managed_via
['user-app', 'volume-log', 'volume-app', 'kibana'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
