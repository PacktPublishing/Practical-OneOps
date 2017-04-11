include_pack "apache"

name "rails"
description "Rails"
type "Platform"
category "Web Application"

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "ruby",
  :cookbook => "oneops.1.ruby",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "*mirror"
  },
  :attributes => {
    "gems" => '{"bundler":""}'
  }


resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
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

resource "railsapp",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "install_dir"   => '/usr/local/railsapp',
    "repository"    => "",
    "remote"        => 'origin',
    "revision"      => 'HEAD',
    "depth"         => 1,
    "submodules"    => 'false',
    "environment"   => '{}',
    "persist"       => '["log","tmp"]',
    "migration_command" => '',
    "restart_command"   => ''
  }

# depends_on
[ { :from => 'ruby',     :to => 'os' },
  { :from => 'ruby',     :to => 'apache'  },
  { :from => 'ruby',     :to => 'library' },
  { :from => 'ruby',     :to => 'download'},
  { :from => 'railsapp', :to => 'ruby'    },
  { :from => 'artifact', :to => 'ruby'    },
  { :from => 'website',  :to => 'ruby'    },
  { :from => 'website',  :to => 'railsapp'}  ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end


# managed_via
[ 'ruby', 'railsapp', 'artifact' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
