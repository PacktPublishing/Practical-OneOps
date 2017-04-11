include_pack "genericlb"

name "nginx"
description "Nginx"
type "Platform"
category "Web Server"
ignore true

platform :attributes => {'autoreplace' => 'false'}
  
resource "nginx",
  :cookbook => "oneops.1.nginx",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => { "version"  => "8.4" },
  :monitors => {
      'nginx-status' =>  { :description => 'BuiltIn Nginx Status',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Seconds'},
                  :cmd => 'check_nginx_status',
                  :cmd_line => '/opt/nagios/libexec/check_nginx.rb',
                  :metrics =>  {
                    'active_connections'   => metric( :unit => '', :description => 'Active Connections', :dstype => 'GAUGE'),
                    'acceped'   => metric( :unit => 'PerSecond', :description => 'Accepted Reqs', :dstype => 'DERIVE'),
                    'handled'   => metric( :unit => 'PerSecond', :description => 'Handled Reqs', :dstype => 'DERIVE'),
                    'reading'   => metric( :unit => '', :description => 'Reading', :dstype => 'GAUGE'),
                    'writing'   => metric( :unit => '', :description => 'Writing', :dstype => 'GAUGE'),
                    'waiting'   => metric( :unit => '', :description => 'Waiting', :dstype => 'GAUGE')                    
                  },
                  :thresholds => {
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
[ { :from => 'nginx',  :to => 'os' },
  { :from => 'nginx',  :to => 'library' },
  { :from => 'build',   :to => 'nginx'  },
  { :from => 'website', :to => 'nginx'  },
  { :from => 'website', :to => 'build'   } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'nginx', 'build', 'website'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
