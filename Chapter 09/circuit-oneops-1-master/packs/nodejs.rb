include_pack "custom"

name "nodejs"
description "Node.js"
type "Platform"
category "Worker Application"
ignore true

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "nodejs",
  :cookbook => "oneops.1.nodejs",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "nodejs programming language environment"
  },
  :attributes => {
    "npm"          => '[]'
  }
  
# depends_on
[ { :from => 'nodejs',  :to => 'os' },
  { :from => 'nodejs',  :to => 'library' },
  { :from => 'nodejs',  :to => 'download'},
  { :from => 'build',   :to => 'nodejs' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'nodejs' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
