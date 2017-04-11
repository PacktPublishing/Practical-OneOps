include_pack "custom"

name "fuse"
description "fuse"
type "Platform"
category "Web Application"

resource "fuse",
  :cookbook => "oneops.1.fuse",
  :design => true,
  :requires => { "constraint" => "1..1" }


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
        'logfile' => '/log/logmon/logmon.log',
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

resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "install_dir"   => '/usr/local/build',
    "repository"    => "",
    "remote"        => 'origin',
    "revision"      => 'HEAD',
    "depth"         => 1,
    "submodules"    => 'false',
    "environment"   => '{}',
    "persist"       => '[]',
    "migration_command" => '',
    "restart_command"   => ''
  }

resource "secgroup",
  :cookbook => "oneops.1.secgroup",
  :design => true,
  :attributes => {
    "inbound" => '[ "* 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0", "9990 9990 tcp 0.0.0.0/0", "8443 8443 tcp 0.0.0.0/0" ]'
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
         :attributes => {
             :version => '7'
         }

# depends_on
[ { :from => 'fuse',     :to => 'os' },
  { :from => 'fuse',     :to => 'user'  },
  { :from => 'fuse',     :to => 'java'  },
  { :from => 'artifact',   :to => 'library' },
  { :from => 'artifact',   :to => 'fuse'  },
  { :from => 'artifact',   :to => 'volume'},
  { :from => 'build',      :to => 'fuse'  },
  { :from => 'daemon',     :to => 'artifact' },
  { :from => 'java',       :to => 'os'},  ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
[ 'fuse','artifact', 'build', 'java' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
