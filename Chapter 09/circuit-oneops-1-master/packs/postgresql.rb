include_pack "lbdb"

name "postgresql"
description "PostgreSQL"
type "Platform"
category "Database Relational SQL"

platform :attributes => {'autoreplace' => 'false'}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "5432 5432 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "postgres-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :help => "Restarts Postgres"
         },
         :attributes => {
             :service_name => 'postgresql-9.2',
             :use_script_status => 'true',
             :pattern => ''
         },
         :monitors => {
             'postgresprocess' => {:description => 'PostgresProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::!:::node.workorder.rfcCi.ciAttributes.secondary_down:::',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'PostgresDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             }
          }

resource "postgresql",
  :cookbook => "oneops.1.postgresql",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {  "version"       => "9.2",
                    "port"          => 5432,
                    "password"      => 'admin',
                    "postgresql_conf" => '{}'
                 },
  :monitors => {    
      'Replicators' =>  { 
        :enable => 'false',
        :description => 'replicator count - sender or receiver',
        :source => '',
        :chart => {'min'=>0, 'unit'=>''},
        :cmd => 'check_replicators',
        :cmd_line => '/opt/nagios/libexec/check_replicators.sh',
        :metrics =>  {
                    'replicators'   => metric( 
                       :unit => '', 
                       :description => 'Replicator count - sender or receiver', 
                       :dstype => 'GAUGE',
                       :display_group => "Replicators"),
                       
                  },
                  :thresholds => {
                  }
                },
      'Backups' =>  { 
        :enable => 'false',
        :description => 'Backup file count. options: user_host path min_back filter',
        :source => '',
        :cmd_options => {
           :user_host => '',
           :path => '/share/backup',
           :min_back => '1440',
           :filter => ''
        },
        :chart => {'min'=>0, 'unit'=>''},
        :cmd => 'check_backups!#{cmd_options[:user_host]}!#{cmd_options[:path]}!#{cmd_options[:min_back]}!#{cmd_options[:filter]}',
        :cmd_line => '/opt/nagios/libexec/check_backups.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$',
        :metrics =>  {
                    'backup_count'   => metric( 
                       :unit => '', 
                       :description => 'backup count', 
                       :dstype => 'GAUGE',
                       :display_group => "Backups"),
                       
                  },
                  :thresholds => {
                  }
                },                
      'PostgresStats' =>  { 
	              :description => 'default metrics',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_postgresql_stats',
                  :cmd_line => '/opt/nagios/libexec/check_sql_pg.rb /etc/nagios3/pg_stats.yaml',
                  :metrics =>  {
                    'active_queries'   => metric( 
          					   :unit => '', 
          					   :description => 'Active Queries', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Queries"),
                    'locks'   => metric( 
          					   :unit => '', 
          					   :description => 'Locks', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Locks"),
                    'wait_locks'   => metric( 
          					   :unit => '', 
          					   :description => 'Wait Locks', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Locks"),
                    'heap_hit'   => metric( 
          					   :unit => 'B', 
          					   :description => 'Heap Hit', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Heap"),
                    'heap_read'   => metric( 
          					   :unit => 'B', 
          					   :description => 'Heap Read', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Heap"),
                    'heap_hit_ratio'   => metric( 
          					   :unit => '%', 
          					   :description => 'Heap Hit Ratio', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Heap"),
                    'index_read'   => metric( 
          					   :unit => 'B', 
          					   :description => 'Index Read', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Index"),
                    'index_hit'   => metric( 
          					   :unit => 'B', 
          					   :description => 'Index Hit', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Index"),
                    'index_hit_ratio'   => metric( 
          					   :unit => '%', 
          					   :description => 'Index Hit Ratio', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Index"),
                    'disk_usage'   => metric( 
          					   :unit => 'B', 
          					   :description => 'Disk Usage', 
          					   :dstype => 'GAUGE',
          					   :display_group => "Storage"),
                  },
                  :thresholds => {
                  }
                }
             },
  :payloads => { 'RequiresComputes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Postgresql",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Compute",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute"
             }
           ]
         }
       ]
    }'
  },
    'master' => {
      'description' => 'Master DB', 
      'definition' => '{ 
         "returnObject": false, 
         "returnRelation": false, 
         "relationName": "base.RealizedAs", 
         "direction": "to", 
         "relationAttrs":[{"attributeName":"priority", "condition":">", "avalue":"1"}],
         "relations": [ 
           { "returnObject": false, 
             "returnRelation": false, 
             "relationName": "manifest.Requires", 
             "direction": "to",
             "targetClassName": "manifest.Platform", 
             "relations": [ 
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Entrypoint",
                 "direction": "from",
                 "relations": [
                   {"returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "relations": [ 
                     { "returnObject": true, 
                       "returnRelation": false, 
                       "relationName": "base.RealizedAs", 
                       "direction": "from",
                       "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"}]
                     }
                    ]
                   }  
                 ]
               }
             ]
           } 
         ] 
      }'  
    },
 'master_redundant' => {
      'description' => 'Master DB in redundant mode', 
      'definition' => '{ 
         "returnObject": false, 
         "returnRelation": false, 
         "relationName": "base.RealizedAs", 
         "direction": "to", 
         "relationAttrs":[{"attributeName":"priority", "condition":">", "avalue":"1"}],
         "relations": [ 
           { "returnObject": false, 
             "returnRelation": false, 
             "relationName": "manifest.Requires", 
             "direction": "to",
             "targetClassName": "manifest.Platform", 
             "relations": [ 
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Entrypoint",
                 "direction": "from",
                 "relations": [
                   {"returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "relations": [ 
                     { "returnObject": false, 
                       "returnRelation": false, 
                       "relationName": "manifest.DependsOn", 
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Compute",                            
                       "relations": [ 
                         { "returnObject": true, 
                           "returnRelation": false, 
                           "relationName": "base.RealizedAs", 
                           "targetClassName": "bom.oneops.1.Compute",                            
                           "direction": "from",
                           "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"}]
                         }
                        ]                       
                     }
                    ]
                   }  
                 ]
               }
             ]
           } 
         ] 
      }'  
    }
  }
    
resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }  

# depends_on
[ 'postgresql'].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from' } 
end

[ 'postgresql'].each do |from|
  relation "#{from}::depends_on::os",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'postgresql' ].each do |from|
  relation "#{from}::depends_on::volume",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'volume',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'postgresql' ].each do |from|
  relation "#{from}::depends_on::lb",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'postgres-daemon'].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from' }
end

[ 'postgres-daemon'].each do |from|
  relation "#{from}::depends_on::os",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'postgres-daemon' ].each do |from|
  relation "#{from}::depends_on::postgresql",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'postgresql',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'database' ].each do |from|
  relation "#{from}::depends_on::postgresql",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'postgresql',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::postgresql",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'postgresql',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'artifact' ].each do |from|
  relation "#{from}::depends_on::database",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'database',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


# managed_via
[ 'postgresql','artifact','postgresql-9.2' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
