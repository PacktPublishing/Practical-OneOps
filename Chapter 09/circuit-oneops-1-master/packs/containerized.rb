name "containerized"
description "Containerized Application"
type "Platform"
category "Other"

ignore true

environment "single", {}
environment "redundant", {}

platform :attributes => {
                "replace_after_minutes" => 60,
                "replace_after_repairs" => 3
        }


resource "image",
  :cookbook => "oneops.1.image",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*registry" },
  :attributes => {
    :image_type => 'registry',
    :image => 'nginx'
  }

resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :attributes => {
    "size"        => '20G',
    "slice_count" => '1'
  },
  :requires => { "constraint" => "0..*", "services" => "storage" }

resource "realm",
  :cookbook => "oneops.1.realm",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {}

resource "container",
  :cookbook => "oneops.1.container",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {
    :image_type => 'registry',
    :image => 'nginx',
    :ports => '{"http":"80"}'
  }

resource "set",
  :cookbook => "oneops.1.set",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "container" },
  :attributes => {
    :replicas => '3',
    :parallelism => '1'
  }


# depends_on

[ { :from => 'set',  :to => 'container' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    # :only => [ 'fungible' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { }
end

[ { :from => 'container',  :to => 'image' },
  { :from => 'container',  :to => 'storage' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "propagate_to" => 'from' }
end

[ { :from => 'container',  :to => 'realm' },
  { :from => 'storage',  :to => 'realm' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { }
end
