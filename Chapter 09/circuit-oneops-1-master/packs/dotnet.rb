include_pack "custom"

name "dotnet"
description "DotNet"
type "Platform"
category "Worker Application"

environment "single", {}
environment "redundant", {}

resource "dotnetcli",
  :cookbook => "oneops.1.dotnetcli",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "dotnetcli install component",
    :services => 'mirror'
  },
  :attributes => {

  }

resource "secgroup",
  :cookbook => "oneops.1.secgroup",
  :design => true,
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0" ]'
  },
  :requires => {
    :constraint => "1..1",
    :services => "compute"
  }
# depends_on
[ { :from => 'dotnetcli',  :to => 'os' },
  { :from => 'build',   :to => 'dotnetcli' } ].each do |link|

  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => { "flex" => false, "min" => 1, "max" => 1 }
end
# managed_via
[ 'dotnetcli'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource => 'compute',
    :attributes => { }
end
