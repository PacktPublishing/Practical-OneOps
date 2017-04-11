include_pack "custom"

name "ruby"
description "Ruby"
type "Platform"
category "Worker Application"

environment "single", {}
environment "redundant", {}

resource "ruby",
  :cookbook => "oneops.1.ruby",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "ruby programming language environment",
    :services => "*mirror"
  },
  :attributes => {
    "gems" => '{"bundler":""}'
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
[{:from => 'ruby', :to => 'os'},
 {:from => 'ruby', :to => 'library'},
 {:from => 'ruby', :to => 'download'},
 {:from => 'artifact', :to => 'ruby'},
 {:from => 'build', :to => 'ruby'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource   => link[:to],
           :attributes    => {"flex" => false, "min" => 1, "max" => 1}
end

# managed_via
[ 'ruby' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
