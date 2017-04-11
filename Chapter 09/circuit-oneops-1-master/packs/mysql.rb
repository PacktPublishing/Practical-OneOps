include_pack "lbdb"

name "mysql"
description "MySQL"
type "Platform"
category "Database Relational SQL"

platform :attributes => {'autoreplace' => 'false'}
  
resource "mysql",
  :cookbook => "oneops.1.mysql",
  :design => true,
  :requires => {
        :constraint => "1..1",
        :services => "mirror"
    },
  :attributes => {  "version"       => "5.5",
                    "port"          => 3306,
                    "password"      => 'mysql',
                    "datadir"       => '/db' },
  :monitors => {    
      'MysqlStats' =>  { 
	              :description => 'Default metrics from nagios check_mysql',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_mysql_stats',
                  :cmd_line => '/opt/nagios/libexec/check_mysql.rb',
                  :metrics =>  {
                    'threads'   => metric( :unit => '', :description => 'Threads', :dstype => 'GAUGE',:display_group => "Activity"),
                    'questions'   => metric( :unit => '', :description => 'Questions', :dstype => 'GAUGE', :display_group => "Activity"),
                    'slow_queries'   => metric( :unit => '', :description => 'Slow queries', :dstype => 'GAUGE', :display_group => "Activity"),
                    'opens'   => metric( :unit => '', :description => 'Opens', :dstype => 'GAUGE', :display_group => "Activity"),
                    'flush_tables'   => metric( :unit => '', :description => 'Flush tables', :dstype => 'GAUGE', :display_group => "Tables"),
                    'open_tables'   => metric( :unit => '', :description => 'Open tables', :dstype => 'GAUGE', :display_group => "Tables"),
                    'queries_per_second_avg'   => metric( :unit => '', :description => 'Queries per second', :dstype => 'GAUGE', :display_group => "Activity")
                  },
                  :thresholds => {
                  }
                }   
  }                 

##Default security group 
resource 'secgroup',
         :attributes => {
           :inbound => '["22 22 tcp 0.0.0.0/0", "3306 3306 tcp 0.0.0.0/0"]'
         },
         :requires   => {
           :constraint => '1..1',
           :services   => 'compute'
         }

# depends_on
[ 'mysql'].each do |from|
  relation "#{from}::depends_on::os",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'mysql' ].each do |from|
  relation "#{from}::depends_on::volume",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'volume',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

[ 'database' ].each do |from|
  relation "#{from}::depends_on::mysql",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'mysql',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end

# managed_via
[ 'mysql' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end

  

# procedures
procedure "snapshot",
  :description => "Snapshot",
  :arguments => {
        "database_name" => {
                "name" => "database_name",
                "defaultValue" => "mydb",
                "dataType" => "string"
        },
        "snapshot_path" => {
                "name" => "snapshot_path",
                "defaultValue" => "/db/snapshot/mydb.sql",
                "dataType" => "string"
        }
   },
  :definition => '{
    "flow": [
        {
            "execStrategy": "one-by-one",
            "relationName": "manifest.Requires",
            "direction": "from",
            "targetClassName": "manifest.oneops.1.Mysql",
            "flow": [
                {
                    "relationName": "base.RealizedAs",
                    "execStrategy": "one-by-one",
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Mysql",
                    "actions": [
                        {
                            "actionName": "snapshot",
                            "stepNumber": 1,
                            "isCritical": true
                        }
                    ]
                }
            ]
        }
    ]
}'

procedure "restore",
  :description => "Restore",
  :arguments => {
        "database_name" => {
                "name" => "database_name",
                "defaultValue" => "mydb",
                "dataType" => "string"
        },
        "snapshot_path" => {
                "name" => "snapshot_path",
                "defaultValue" => "/db/snapshot/mydb.sql",
                "dataType" => "string"
        }
   },
  :definition => '{
    "flow": [
        {
            "execStrategy": "one-by-one",
            "relationName": "manifest.Requires",
            "direction": "from",
            "targetClassName": "manifest.oneops.1.Mysql",
            "flow": [
                {
                    "relationName": "base.RealizedAs",
                    "execStrategy": "one-by-one",
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Mysql",
                    "actions": [
                        {
                            "actionName": "restore",
                            "stepNumber": 1,
                            "isCritical": true
                        }
                    ]
                }
            ]
        }
    ]
}'

