include_pack "custom"

name "puppetexample"
description "Puppet Example Module Usage"
type "Platform"
category "Other"
ignore true

environment "single", {}
environment "redundant", {}

resource "test_wo",
  :cookbook => "oneops.1.test_wo",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "puppet test_wo module"
  }
  
# depends_on
[ { :from => 'test_wo', :to => 'compute' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'test_wo' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
