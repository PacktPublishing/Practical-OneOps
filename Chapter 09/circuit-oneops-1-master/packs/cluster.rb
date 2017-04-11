include_pack "base"

name "cluster"
description "Cluster"
type "Platform"
ignore true
category "General"

platform :attributes => {'autoreplace' => 'false'}

resource "crm",
  :except => [ 'single' ],
  :design => false,
  :cookbook => "oneops.1.crm",
  :requires => { "constraint" => "1..1" }
  
resource "cluster",
  :except => [ 'single' ],
  :design => false,
  :cookbook => "oneops.1.cluster",
  :requires => { "constraint" => "1..1" },
  :payloads => {
    'crm_resources' => {
      'description' => 'Cluster Resources', 
      'definition' => '{ 
         "returnObject": true, 
         "returnRelation": false, 
         "relationName": "bom.DependsOn", 
         "direction": "from", 
         "targetClassName": "bom.Crm", 
         "relations": [ 
           { "returnObject": true, 
             "returnRelation": false, 
             "relationName": "bom.DependsOn", 
             "direction": "from"
           } 
         ] 
      }'  
    },
    'crm_storage' => {
      'description' => 'Cluster Storage', 
      'definition' => '{ 
         "returnObject": false, 
         "returnRelation": false, 
         "relationName": "bom.DependsOn", 
         "direction": "from", 
         "targetClassName": "bom.Crm", 
         "relations": [ 
           { "returnObject": false, 
             "returnRelation": false, 
             "relationName": "bom.DependsOn", 
             "direction": "from",
             "targetClassName": "bom.Volume", 
             "relations": [ 
                { "returnObject": true, 
                  "returnRelation": false, 
                  "relationName": "bom.DependsOn", 
                  "direction": "from",
                  "targetClassName": "bom.Storage" 
                }
              ]
            } 
          ] 
       }'
     }
  }  


resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "size"          => '10G'  
  }  

resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {
    "mount_point"   => '/data',
    "fstype"        => 'xfs'    
  }
  
entrypoint "compute",
  :only => [ 'single' ]
  
entrypoint "cluster",
  :except => [ 'single' ]

# DependsOn
[ 'crm' ].each do |from|
  relation "#{from}::depends_on::os",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'cluster' ].each do |from|
  relation "#{from}::depends_on::crm",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'crm',
    :attributes    => { "flex" => true, "min" => 2, "max" => 2 } 
end

[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::compute",
    :only => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::cluster",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'cluster',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'crm' ].each do |from|
  relation "#{from}::depends_on::volume",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'volume',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'volume' ].each do |from|
  relation "#{from}::depends_on::storage",
    :only => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'storage',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'volume' ].each do |from|
  relation "#{from}::depends_on_converge::storage",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'storage',
    :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 } 
end


# ManagedVia
[ 'cluster', 'crm' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

# SecuredBy
[ 'cluster'].each do |from|
  relation "#{from}::secured_by::sshkeys",
    :except => [ '_default','single'],
    :relation_name => 'SecuredBy',
    :from_resource => from,
    :to_resource   => 'sshkeys',
    :attributes    => { } 
end
