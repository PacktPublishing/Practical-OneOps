include_pack "genericlb"

name "play"
description "Play App"
type "Platform"
category "Web Application"

variable "appName",
         :description => 'Application name',
         :value => 'playapp'

variable "appOpts",
        :description => 'Java Opts',
        :value => ''

variable "httpPort",
        :description => 'Http Port for your play app',
        :value => '9000'

variable "AppSecret",
        :description => 'App secret key',
        :value => ''

resource "user-app",
  :cookbook => "oneops.1.user",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
    "username" => "app",
    "description" => "App User",
    "home_directory" => "/home/app",
    "system_account" => true,
    "sudoer" => true
  }

resource "playApp",
:cookbook => "oneops.1.Playapp",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
      :http_port => '$OO_LOCAL{httpPort}',
      :app_secret => '$OO_LOCAL{AppSecret}',
    :log_file => '/log/$OO_LOCAL{appName}',
    :application_conf_file => '/app/$OO_LOCAL{appName}',
    :app_name => '$OO_LOCAL{appName}',
    :app_location => '/app/$OO_LOCAL{appName}',
    :app_opts => '$OO_LOCAL{appOpts}',
    :app_dir => './'
}

resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  },
  :monitors => {
         'URL' => {:description => 'URL',
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
                       'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
                       'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
                   },
                   :thresholds => {

                   }
         },
          'exceptions' => {:description => 'Exceptions',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                     :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                     :cmd_options => {
                         'logfile' => '/app',
                         'warningpattern' => 'Exception',
                         'criticalpattern' => 'Exception'
                     },
                     :metrics => {
                         'logexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                         'logexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                         'logexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                         'logexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                     },
                     :thresholds => {
                       'CriticalExceptions' => threshold('15m', 'avg', 'logexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
                    }
           }
       }


resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "9000 9000 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}

resource "volume-log",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/log',
                    "size"          => '100%FREE',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('1m','avg','space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                    'LowDiskInode' => threshold('1m','avg','inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                  },
                },
    }

resource "volume-app",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/app',
                    "size"          => '60%VG',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('1m','avg','space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                    'LowDiskInode' => threshold('1m','avg','inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                  },
                },
    }

# depends_on
[ { :from => 'volume-app',    :to => 'os' },
  { :from => 'volume-app',    :to => 'user-app' },
  { :from => 'os',    :to => 'compute' },
  { :from => 'user-app',      :to => 'os' },
  { :from => 'java',       :to => 'os' },
  { :from => 'playApp',     :to => 'user-app' },
  { :from => 'playApp',     :to => 'java'  },
  { :from => 'playApp',   :to => 'artifact'  },
  { :from => 'playApp',   :to => 'download'  },
  { :from => 'artifact',   :to => 'library' },
  { :from => 'volume-log',   :to => 'volume-app'  },
  { :from => 'artifact',   :to => 'volume-log'  },
  { :from => 'download',   :to => 'volume-log'  },
  { :from => 'artifact',   :to => 'volume-app'  } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
[ 'user-app', 'playApp', 'artifact', 'java', 'library', 'volume-log', 'volume-app' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
