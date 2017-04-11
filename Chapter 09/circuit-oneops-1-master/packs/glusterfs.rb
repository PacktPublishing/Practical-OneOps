include_pack "base"

name "glusterfs"
description "GlusterFS"
type "Platform"
category "Distributed Filesystems"
        
resource "glusterfs",
  :cookbook => "oneops.1.glusterfs",
  :design => true,
  :requires => {
    :constraint => "1..*",
    :services => "mirror"
    },
  :attributes => {  
                    "store"   => '/data',
                    "volopts" => '{}',
                    "replicas" => "1",
                    "mount_point" => '/mnt/glusterfs'
                 }

resource "volume",
  :requires => { "constraint" => "1..1", "services" => "compute" }
  
  
resource "secgroup",
   :cookbook => "oneops.1.secgroup",
   :design => true,
   :attributes => {
       "inbound" => '[ "22 22 tcp 0.0.0.0/0", "24007 24007 tcp 0.0.0.0/0", "38465 38467 tcp 0.0.0.0/0", "49152 49153 tcp 0.0.0.0/0" ]'
   },
   :requires => {
       :constraint => "1..1",
       :services => "compute"
   }  


# depends_on
[ { :from => 'glusterfs',   :to => 'volume' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "flex" => true, "min" => 2, "max" => 10 }

[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
[ 'glusterfs' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
