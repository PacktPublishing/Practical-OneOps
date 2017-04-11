include_pack "base"

name "genericmq"
description "Queue and topic"
ignore true
type "Platform"
category "Messaging"


resource "queue",
  :cookbook => "oneops.1.queue",
  :design => true,
  :requires => { 
      :constraint => "0..*",
      :help => 'Queues'
    }
  
resource "topic",
  :cookbook => "oneops.1.topic",
  :design => true,
  :requires => { 
      :constraint => "0..*",
      :help => 'Topic'
  } 

# depends on
relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "flex" => true, "min" => 2, "max" => 10 }


 # managed_via
['queue', 'topic'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
