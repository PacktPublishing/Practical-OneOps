include_pack "genericlb"

name "apache"
description "Apache"
type "Platform"
category "Web Server"

resource "apache",
  :cookbook => "oneops.1.apache",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "This is an HTML help text for apache component"
  },
  :attributes => {
    "install_type" => 'repository',
    "build_options" => '{"srcdir":"/usr/local/src/apache","version":"2.2.21","prefix":"/usr/local/apache","configure":"--enable-so --enable-mods-shared=all"}',
    "ports" => '["80","443"]',
    "user" => '',
    "contact" => 'ops@example.com',
    "request_timeout" => '300',
    "keepalive" => 'On',
    "signature" => 'On',
    "tokens" => 'Prod',
    "modules" => '["mod_log_config","mod_mime","mod_dir","mod_status","mod_alias","mod_auth_basic","mod_authz_host","mod_ssl","mod_setenvif","mod_headers"]',
    "prefork" => '{"startservers":16,"minspareservers":16,"maxspareservers":32,"serverlimit":400,"maxclients":400,"maxrequestsperchild":10000}',
    "worker" => '{"startservers":4,"maxclients":1024,"minsparethreads":64,"maxsparethreads":192,"maxcthreadsperchild":64,"maxrequestsperchild":0}'
  },
  :monitors => {
      'ServerStatus' =>  { :description => 'ServerStatus',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_apache',
                  :cmd_line => '/opt/nagios/libexec/check_apache.rb',
                  :metrics =>  {
                    'cpu_user'   => metric( :unit => 'Percent', :description => 'CPU User', :dstype => 'DERIVE',  :display_group => "CPU"),
                    'cpu_sys'   => metric( :unit => 'Percent', :description => 'CPU System', :dstype => 'DERIVE',  :display_group => "CPU"),
                    'requests_sec'   => metric( :unit => '', :description => 'Requests/sec', :dstype => 'DERIVE', :display_group => "Request Rate"),
                    'traffic_sec'   => metric( :unit => '', :description => 'Traffic/sec', :dstype => 'DERIVE',  :display_group => "Traffic"),
                    'active_requests'   => metric( :unit => '', :description => 'Active Requests', :dstype => 'GAUGE',  :display_group => "Active Requests"),
                    'idle_workers'   => metric( :unit => '', :description => 'Idle Workers', :dstype => 'GAUGE', :display_group => "Workers")
                  },
                  :thresholds => {
                     'TooBusy' => threshold('5m','avg','idle_workers',trigger('<',5,5,5),reset('>',5,5,5)),
                     'HighUserCpu' => threshold('5m','avg','cpu_user',trigger('>',60,5,1),reset('<',60,5,1)),
                     'HighSysCpu' => threshold('5m','avg','cpu_sys',trigger('>',30,5,1),reset('<',30,5,1))
                  }
                },
}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0", "443 443 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
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
  
resource "lb",
  :except => [ 'single' ],
  :design => false,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "lb,dns" },
  :attributes => {
    "stickiness"    => ""
  }  

resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  },
  :monitors => {
         'url-monitor' => {:description => 'URL',
                   :source => '',
                   :chart => {'min' => 0, 'unit' => ''},
                   :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
                   :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
                   :cmd_options => {
                       'host' => 'localhost',
                       'port' => '80',
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
          'exceptions' => {:description => 'Exceptions',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                     :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                     :cmd_options => {
                         'logfile' => '/var/log/httpd/error.log',
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

resource "waf",
  :cookbook => "oneops.1.waf",
  :design => true,
  :requires => { "constraint" => "0..1" }

resource "hostname",
        :cookbook => "oneops.1.fqdn",
        :design => true,
        :requires => {
             :constraint => "0..1",
             :services => "dns",
             :help => "optional hostname dns entry"
         }


resource "website",
  :cookbook => "oneops.1.website",
  :design => true,
  :requires => { "constraint" => "1..*" },
  :attributes => {
    "server_name"   => "",
    "port"          => "80",
    "root"          => "",
    "index"         => "index.html",
    "extra"         => <<-eos
eos
  },
  :monitors => {
      'Url' =>  { :description => 'Url Monitor',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_website',
                  :cmd_line => '/opt/nagios/libexec/check_http -H localhost',
                  :metrics =>  {
                    'time'   => metric( :unit => '', :description => 'Response Time', :dstype => 'GAUGE'),
                    'size'   => metric( :unit => '', :description => 'Size', :dstype => 'GAUGE')
                  },
                  :thresholds => {
                     'SlowWebsite' => threshold('5m','avg','time',trigger('>',1,5,1),reset('<',1,5,1)),
                  }
                }
}


# depends_on
[ { :from => 'apache',  :to => 'compute' },
  { :from => 'apache',  :to => 'os' },  
  { :from => 'apache',  :to => 'library' },
  { :from => 'build',   :to => 'apache'  },
  { :from => 'hostname', :to => 'compute'  },
  { :from => 'artifact', :to => 'apache'  },
  { :from => 'waf',     :to => 'apache'  },
  { :from => 'website', :to => 'apache'  },
  { :from => 'website', :to => 'waf'     },
  { :from => 'website', :to => 'build'   },
  { :from => 'website', :to => 'artifact'}  ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
[ 'apache', 'build', 'artifact', 'website', 'waf' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
