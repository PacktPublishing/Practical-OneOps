include_pack "nginx"

name "rails-nginx"
description "Rails with Nginx"
type "Platform"
category "Web Application"

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "ruby",
  :cookbook => "oneops.1.ruby",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :attributes => {
    "version"       => "1.8.7",
    "gems"          => '{"bundler":""}'
  }

resource "railsapp",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*", "services" => "*mirror" },
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
  { :from => 'ruby',     :to => 'nginx'  },
  { :from => 'ruby',     :to => 'library' },
  { :from => 'ruby',     :to => 'download'},
  { :from => 'railsapp', :to => 'ruby'    },
  { :from => 'website',  :to => 'ruby'    } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end


# managed_via
[ 'ruby', 'railsapp' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
