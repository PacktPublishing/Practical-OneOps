include_pack "base"

name "genericlb"
description "Generic Load Balancer"
type "Platform"
ignore true
category "Generic"

resource "lb",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
  :attributes => {
    "stickiness"    => ""
  },
  :payloads => {
  'primaryactiveclouds' => {
      'description' => 'primaryactiveclouds',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.Lb",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                  {"attributeName":"adminstatus", "condition":"neq", "avalue":"offline"}],
                 "relationName": "base.Consumes",
                 "direction": "from",
                 "targetClassName": "account.Cloud",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                     "relationName": "base.Provides",
                     "direction": "from",
                     "targetClassName": "cloud.service.Netscaler"
                   }
                 ]
               }
             ]
           }
         ]
      }'
    }
  }

resource "lb-certificate",
  :cookbook => "oneops.1.certificate",
  :design => true,
  :requires => { "constraint" => "0..1", 'services' => '*certificate' },
  :attributes => {}


[ 'lb' ].each do |from|
  relation "#{from}::depends_on::lb-certificate",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource => 'lb-certificate',
    :attributes => { "propagate_to" => 'from', "flex" => false, "min" => 0, "max" => 1 }
end


# depends_on

[ 'lb' ].each do |from|
  relation "#{from}::depends_on::compute",
    :only => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>2, "min" => 2, "max" => 10}
end

# -d name due to pack sync logic uses a map keyed by that name - it doesnt get put into cms
[ 'lb' ].each do |from|
  relation "#{from}::depends_on::compute-d",
    :only => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "flex" => false }
end


[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::lb",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end

[ 'firewall' ].each do |from|
  relation "#{from}::depends_on::lb",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end
