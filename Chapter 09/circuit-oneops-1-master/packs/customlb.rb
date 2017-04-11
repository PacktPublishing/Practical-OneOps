include_pack "genericlb"

name         "customlb"
description  "Custom With LB"
type         "Platform"
category     "Other"

resource 'hostname',
         :cookbook => 'oneops.1.fqdn',
         :design => true,
         :requires => {
             :constraint => '0..1',
             :services => 'dns',
             :help => 'Optional hostname dns entry'
         }

resource "build",
         :cookbook => "oneops.1.build",
         :design => true,
         :requires => {"constraint" => "0..*"},
         :attributes => {"repository" => "",
                         "remote" => 'origin',
                         "revision" => 'master',
                         "depth" => 1,
                         "submodules" => 'false',
                         "environment" => '{}',
                         "persist" => '[]',
                         "migration_command" => '',
                         "restart_command" => ''
         },
         :payloads => {'daemonizedBy' => {
             'description' => 'Daemons',
             'definition' => '{
       "returnObject": true,
       "returnRelation": false,
       "relationName": "bom.DependsOn",
       "direction": "to",
       "targetClassName": "bom.oneops.1.Daemon",
       "relations": []
    }'
         }
         }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => {"constraint" => "0..*"},
         :attributes => {

         }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "java",
         :cookbook => "oneops.1.java",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "mirror",
             :help => "Java Programming Language Environment"
         },
         :attributes => {
             :install_dir => "/usr/lib/jvm",
             :flavor => "oracle",
             :jrejdk => "server-jre",
             :version => "8",
             :uversion => "",
             :binpath => "",
             :sysdefault => "true"
         }

resource "keystore",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "0..1"},
         :attributes => {
             "keystore_filename" => "/var/lib/certs/keystore.jks"
         }

# depends_on
[{:from => 'build', :to => 'download'},
 {:from => 'build', :to => 'library'},
 {:from => 'build', :to => 'compute'},
 {:from => 'artifact', :to => 'volume'},
 {:from => 'artifact', :to => 'download'},
 {:from => 'artifact', :to => 'file'},
 {:from => 'artifact', :to => 'java'},
 {:from => 'download', :to => 'volume'},
 {:from => 'java', :to => 'compute'},
 {:from => 'keystore', :to => 'java'},
 {:from => 'keystore', :to => 'certificate'},
 {:from => 'artifact', :to => 'library'},
 {:from => 'artifact', :to => 'compute'},
 {:from => 'artifact', :to => 'keystore'},
 {:from => 'hostname', :to => 'os'},
 {:from => 'daemon', :to => 'artifact'},
 {:from => 'daemon', :to => 'build'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end


['fqdn'].each do |from|
  relation "#{from}::depends_on::compute",
           :only => ['_default', 'single'],
           :relation_name => 'DependsOn',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {"propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1}
end


# managed_via
['build', 'artifact', 'java', 'keystore' ].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
