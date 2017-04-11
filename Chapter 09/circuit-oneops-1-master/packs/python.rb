ignore true
include_pack "custom"

name "python"
description "Python"
type "Platform"
category "Worker Application"

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "python",
  :cookbook => "oneops.1.python",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "Python programming language environment"
  },
  :attributes => {
    "install_type" => 'repository'
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
[ { :from => 'python',  :to => 'os' },
  { :from => 'python',  :to => 'library' },
  { :from => 'python',  :to => 'download'},
  { :from => 'build',   :to => 'python' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'python' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
