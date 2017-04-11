include_pack "cluster"

name "nfs"
description "NFS"
type "Platform"
category "Infrastructure Service"
ignore true

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "nfs",
  :cookbook => "oneops.1.nfs",
  :design => true,
  :requires => { "constraint" => "1..1" }


# depends_on
[ 'nfs'].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'nfs' ].each do |from|
  relation "#{from}::depends_on::volume",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'volume',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'crm' ].each do |from|
  relation "#{from}::depends_on::nfs",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'nfs',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


# managed_via
[ 'nfs' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
