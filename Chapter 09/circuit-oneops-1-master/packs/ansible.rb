include_pack "genericlb"

name "Ansible"
description "Ansible"
type "Platform"
category "Automation"

environment "single", {}
environment "redundant", {}

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

resource 'os',
          :cookbook => 'oneops.1.os',
          :design => true,
          :attributes => {
            :ostype => 'centos-7.2'
          },
          :requires => {
            :constraint => "1..1",
            :services => "compute"
          }

resource "ansible",
         :cookbook => "oneops.1.ansible",
         :design => true,
         :attributes => {},
         :requires => {
            :constraint => "1..1"
         }

resource "ansible-role",
         :cookbook => "oneops.1.ansiblerole",
         :design => true,
         :attributes => {},
         :requires => {
            :constraint => "0..*"
         }

# depends_on
 [{ :from => 'ansible',:to => 'os' },
  { :from => 'ansible-role',:to => 'ansible' }].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => true, "min" => 2, "max" => 10 }

#managed_via
['ansible','ansible-role'].each do |from|
   relation "#{from}::managed_via::compute",
     :except => [ '_default' ],
     :relation_name => 'ManagedVia',
     :from_resource => from,
     :to_resource   => 'compute',
     :attributes    => { } 
 end

