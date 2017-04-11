name "powerdns"
description "PowerDNS"
type "Platform"
category "Infrastructure Service"
ignore true

include_pack "mysql"
 
variable "dbuser",
  :value => "powerdns",
  :only => [ '_default' ]
   
resource "pdns",
  :cookbook => "oneops.1.powerdns",
  :requires => { "constraint" => "1..1" },
  :attributes => { }                                             
    
# depends_on
[ 'pdns' ].each do |from|
  relation "#{from}::depends_on::database",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'database',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


# managed_via
[ 'pdns' ].each do |from|
  relation "#{from}::managed_via::compute",
    :only => [ 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

[ 'pdns' ].each do |from|
  relation "#{from}::managed_via::cluster",
    :only => [ 'redundant' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'cluster',
    :attributes    => { } 
end
       