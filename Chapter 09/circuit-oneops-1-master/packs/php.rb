include_pack "apache"

name "php"
description "PHP"
type "Platform"
category "Web Application"

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "php",
  :cookbook => "oneops.1.php",
  :design => true,
  :requires => { 
      :constraint => "1..1",
      :services => "mirror"
    },
  :attributes => {
    "install_type" => 'repository',
    "version" => 'default',
    "build_options" => '{"srcdir":"/usr/local/src/php","version":"PHP_5_3_10","prefix":"/usr/local/php","configure":""}'
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

resource "phpapp",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "install_dir"   => '/usr/local/phpapp',
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

# depends_on
[ { :from => 'php',     :to => 'os' },
  { :from => 'php',     :to => 'apache'  },
  { :from => 'php',     :to => 'library' },
  { :from => 'php',     :to => 'download'},
  { :from => 'phpapp',  :to => 'php'     },
  { :from => 'website', :to => 'phpapp'  },
  { :from => 'website', :to => 'php'     } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end


# managed_via
[ 'php', 'phpapp' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
