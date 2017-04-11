include_pack "generic_ring"

name "orientdb"
description "OrientDB"
type "Platform"
category "Database NoSQL"

resource "orientdb",
	:cookbook => "oneops.1.orientdb",
	:design => true,
	:requires => {"constraint" => "1..1" }

resource "secgroup",
	:cookbook => "oneops.1.secgroup",
	:design => true,
	:attributes => {
		"inbound" => '[ "22 22 tcp 0.0.0.0/0", "1024 65535 tcp 0.0.0.0/0" ]'
	},
	:requires => {
		:constraint => "1..1",
		:services => "compute"
	}

resource 'java',
	:cookbook => 'oneops.1.java',
	:design => true,
	:requires => {
		:constraint => '1..1',
		:services => '*mirror',
		:help => 'Java Programming Language Environment'
	},
	:attributes => {
		:version => '7'
	}

#depends_on
[ { :from => 'orientdb', :to => 'os' },
  { :from => 'orientdb', :to => 'java'},
  { :from => 'java', :to => 'os'}, ].each do |link|
	relation "#{link[:from]}::depends_on::{link[:to]}",
	:relation_name => 'DependsOn',
	:from_resource => link[:from],
	:to_resource => link[:to],
	:attributes => { "flex" => false, "min" => 1, "max" => 1 }
end

#managed_via
['orientdb','java'].each do |from|
	relation "#{from}::managed_via::compute",
		:except => ['_default' ],
		:relation_name => 'ManagedVia',
		:from_resource => from,
		:to_resource => 'compute',
		:attributes => {}
end
