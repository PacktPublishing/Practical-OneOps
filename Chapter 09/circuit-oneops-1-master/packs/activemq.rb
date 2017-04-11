include_pack "genericmq"

name "activemq"
description "ActiveMQ"
type "Platform"
category "Messaging"

platform :attributes => {'autoreplace' => 'false'}

resource 'activemq',
    :cookbook => "oneops.1.activemq",
    :design => true,
    :requires => {
      :constraint => "1..1",
      :services => "mirror",
      :help => 'ActiveMQ Server'
    },
    :monitors => {
       'Log' => {:description => 'Log',
          :source => '',
          :chart => {'min' => 0, 'unit' => ''},
          :cmd => 'check_logfiles!logmqexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
          :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
          :cmd_options => {
              'logfile' => '/var/log/activemq/activemq.log',
              'warningpattern' => 'OutOfMemory',
              'criticalpattern' => 'OutOfMemory'
          },
          :metrics => {
          'logmqexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
          'logmqexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
          'logmqexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
          'logmqexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
          },
          :thresholds => {
          'CriticalExceptions' => threshold('15m', 'avg', 'logmqexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
          }
      },
        'Memory' => {:description => 'Memory Status',
                :source => '',
                :chart => {'min' => 0, 'unit' => ''},
                :cmd => 'check_activemq_mem!:::node.workorder.rfcCi.ciAttributes.adminconsolesecure:::!:::node.workorder.rfcCi.ciAttributes.adminconsoleport:::!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.authenabled:::!:::node.workorder.rfcCi.ciAttributes.adminusername:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::',
                :cmd_line => '/opt/nagios/libexec/check_activemq_mem.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$',
                :cmd_options => {
                     'path' => '/admin/index.jsp?printable=true'
                   },
                :metrics => {
                    'Temp_percent_used' => metric(:unit => '', :description => 'Temp percent used', :dstype => 'GAUGE'),
                    'Memory_percent_used' => metric(:unit => '', :description => 'Memory percent used', :dstype => 'GAUGE'),
                    'Store_percent_used' => metric(:unit => '', :description => 'Store percent used', :dstype => 'GAUGE')
                },
                :thresholds => {

                }
      },'BrokerStatus' =>  { :description => 'BrokerStatus',
          :source => '',
          :chart => {'min'=>0, 'unit'=>''},
          :cmd => 'check_activemq!:::node.workorder.rfcCi.ciAttributes.adminconsolesecure:::!:::node.workorder.rfcCi.ciAttributes.adminconsoleport:::!:::node.workorder.rfcCi.ciAttributes.logpath:::!:::node.workorder.rfcCi.ciAttributes.authenabled:::!:::node.workorder.rfcCi.ciAttributes.adminusername:::!:::node.workorder.rfcCi.ciAttributes.adminpassword:::',
          :cmd_line => '/opt/nagios/libexec/check_activemq.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$',
          :metrics =>  {
          'queue_count'   => metric(
          :unit => '',
          :description => 'Queue Count',
          :dstype => 'GAUGE',
          :display_group => "Queues"),
          'queue_backlog'   => metric(
          :unit => '',
          :description => 'Queue Backlog',
          :dstype => 'GAUGE',
          :display_group => "Queues"),
          'queue_consumer_count'   => metric(
          :unit => '',
          :description => 'Queue Consumer Count',
          :dstype => 'GAUGE',
          :display_group => "Queues"),
          'queue_enqueues'   => metric(
          :unit => 'PerSecond',
          :description => 'Queue in messages /sec',
          :dstype => 'DERIVE',
          :display_group => "Queue Rates" ),
          'queue_dequeues'   => metric(
          :unit => 'PerSecond',
          :description => 'Queue out messages /sec',
          :dstype => 'DERIVE',
          :display_group => "Rates"),
          'topic_count'   => metric(
          :unit => '',
          :description => 'Topic Count',
          :dstype => 'GAUGE',
          :display_group => "Topics"),
          'topic_backlog'   => metric(
          :unit => '',
          :description => 'Topic Backlog',
          :dstype => 'GAUGE',
          :display_group => "Topics"),
          'topic_consumer_count'   => metric(
          :unit => '',
          :description => 'Topic Consumer Count',
          :dstype => 'GAUGE',
          :display_group => "Topics"),
          'topic_enqueues'   => metric(
          :unit => 'PerSecond',
          :description => 'Topic in messages /sec',
          :dstype => 'DERIVE',
          :display_group => "Topic Rates"),
          'topic_dequeues'   => metric(
          :unit => 'PerSecond',
          :description => 'Topic out messages /sec',
          :dstype => 'DERIVE',
          :display_group => "Topic Rates"),
          }
      }
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
             :install_dir => '/usr/lib/jvm',
             :jrejdk => 'jdk',
             :version => '8',
             :sysdefault => 'true',
             :flavor => 'openjdk'
         }

resource "vol-data",
    :cookbook => "oneops.1.volume",
    :design => true,
    :requires => {"constraint" => "1..1", "services" => "compute"},
    :attributes => {"mount_point" => '/data',
      "size" => '100%FREE',
      "device" => '',
      "fstype" => 'ext4',
      "options" => ''
    },
    :monitors => {
      'usage' => {'description' => 'Usage',
      'chart' => {'min' => 0, 'unit' => 'Percent used'},
      'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
      'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
      'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
      'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
      :thresholds => {
          'LowDiskSpace' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
          'LowDiskInode' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
          },
      }
}

resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :attributes => {
    "size"        => '10G',
    "slice_count" => '1'
  },
  :requires => { "constraint" => "0..*", "services" => "storage" }

resource "volume-externalstorage",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "0..1", "services" => "compute,storage"},
         :attributes => {:mount_point => '/externalstorage',
                         :size => '100%FREE',
                         :device => '',
                         :fstype => 'ext4',
                         :options => ''
         },
         :monitors => {
           'usage' => {'description' => 'Usage',
                       'chart' => {'min' => 0, 'unit' => 'Percent used'},
                       'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                       'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                       'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                     'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                       :thresholds => {
                         'LowDiskSpace' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                         'LowDiskInode' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                       }
           }
          }

resource "hostname",
    :cookbook => "oneops.1.fqdn",
    :design => true,
    :requires => {
      :constraint => "1..1",
      :services => "dns",
      :help => "optional hostname dns entry"
}

resource 'secgroup',
    :cookbook   => 'oneops.1.secgroup',
    :design     => true,
    :attributes => {
      :inbound => '["22 22 tcp 0.0.0.0/0", "61616 61616 tcp 0.0.0.0/0", "61617 61617 tcp 0.0.0.0/0", "8161 8161 tcp 0.0.0.0/0","8099 8099 tcp 0.0.0.0/0" , "1098 1098 tcp 0.0.0.0/0"]'
    },
    :requires   => {
      :constraint => '1..1',
      :services   => 'compute'
    }
resource "configfile",
  :cookbook => "oneops.1.file",
  :design => true,
  :requires => {
    :constraint => "0..*",
    :help => "This is used to create the config files. Copy the content in the content field and provide the complete path including the name in the path."
  }

resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }


resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }

resource "haproxy",
  :cookbook => "oneops.1.haproxy",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :monitors => {
      'stats' => {:description => 'stats',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_haproxy',
                     :cmd_line => '/opt/nagios/libexec/check_haproxy.rb',
                     # see http://www.haproxy.org/download/1.5/doc/configuration.txt for more detail
                     :metrics => {
                         'requests' => metric(:unit => 'req/sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                         'current_sessions' => metric(:unit => 'count', :description => 'Current Sessions', :dstype => 'GAUGE'),
                         'errors_req' => metric(:unit => 'errors_req/sec', :description => 'Error Requests /sec', :dstype => 'DERIVE'),
                         'errors_conn' => metric(:unit => 'errors_conn/sec', :description => 'Error Connections /sec', :dstype => 'DERIVE'),
                         'errors_resp' => metric(:unit => 'errors_resp/sec', :description => 'Error Resp /sec', :dstype => 'DERIVE'),
                         'bytes_in' => metric(:unit => 'bytes/sec', :description => 'Bytes in /sec', :dstype => 'DERIVE'),
                         'bytes_out' => metric(:unit => 'bytes/sec', :description => 'Bytes out /sec', :dstype => 'DERIVE')
                     }
           }
  }

resource "activemq-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :help => "Restarts AMQ"
         },
         :attributes => {
             :service_name => 'activemq',
             :use_script_status => 'true',
             :pattern => 'activemq'
         },
         :monitors => {
             'activemqprocess' => {:description => 'ActiveMQProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::!:::node.workorder.rfcCi.ciAttributes.secondary_down:::',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'ActiveMQDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             }
          }

resource "keystore",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "0..1"},
         :attributes => {
             "keystore_filename" => "$OO_LOCAL{keystorepath}"
  }

resource "queue",
  :cookbook => "oneops.1.queue",
  :design => true,
  :requires => {
      :constraint => "0..*",
      :help => 'Queues'
    },
    :payloads => {
           'activemq' => {
             :description => 'Activemq',
             :definition  => '{
                "returnObject": true,
                "returnRelation": false,
                "relationName": "bom.DependsOn",
                "direction": "from",
                "targetClassName": "bom.oneops.1.Activemq"
              }'
           }
         } ,
   :monitors => {
      'QueueStatus' =>  {
            :description => 'QueuesStatus',
            :source => '',
            :chart => {'min'=>0, 'unit'=>''},
           :cmd => 'check_amq_queue!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminconsolesecure]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminconsoleport]:::!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.queuename:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:logpath]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:authenabled]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminusername]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminpassword]:::',
            :cmd_line => '/opt/nagios/libexec/check_amq_queue.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$ $ARG7$ $ARG8$',
            :cmd_options => {
               'path' => '/admin/xml/queues.jsp'
            },
            :metrics =>  {
              'queue_pending_count'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Pending Messages /sec'),
              'queue_consumer_count'   => metric(
                  :unit => '',
                  :description => 'Queue Consumer Count'),
              'queue_enqueues'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Queue in messages /sec', :dstype => 'DERIVE'),
              'queue_dequeues'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Queue out messages /sec' ,:dstype => 'DERIVE')
            }
        }
  }

resource "topic",
  :cookbook => "oneops.1.topic",
  :design => true,
  :requires => {
      :constraint => "0..*",
      :help => 'Topic'
    },
    :payloads => {
           'activemq' => {
             :description => 'Activemq',
             :definition  => '{
                "returnObject": true,
                "returnRelation": false,
                "relationName": "bom.DependsOn",
                "direction": "from",
                "targetClassName": "bom.oneops.1.Activemq"
              }'
           }
         }  ,
   :monitors => {
      'TopicStatus' =>  {
            :description => 'TopicStatus',
            :source => '',
            :chart => {'min'=>0, 'unit'=>''},
            :cmd => 'check_amq_topic!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminconsolesecure]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminconsoleport]:::!#{cmd_options[:path]}!:::node.workorder.rfcCi.ciAttributes.topicname:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:logpath]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:authenabled]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminusername]:::!:::node.workorder.payLoad[:activemq][0][:ciAttributes][:adminpassword]:::',
            :cmd_line => '/opt/nagios/libexec/check_amq_topic.rb $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$ $ARG7$  $ARG8$' ,
            :cmd_options => {
               'protocol' => 'http',
               'port' => '8161',
               'path' => '/admin/xml/topics.jsp'
            },
            :metrics =>  {
              'topic_pending_count'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Pending Messages /sec'),
              'topic_consumer_count'   => metric(
                  :unit => '',
                  :description => 'Topic Consumer Count'),
              'topic_enqueues'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Topic in messages /sec' ,:dstype => 'DERIVE'),
              'topic_dequeues'   => metric(
                  :unit => 'PerSecond',
                  :description => 'Topic out messages /sec', :dstype => 'DERIVE')
            }
        }
  }

variable "keystorepath",
         :description => 'Keystore path',
         :value => '/opt/keystore/broker.ks'

resource "compute",
  :cookbook => "oneops.1.compute",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns" },
  :attributes => {
      "size"    => "M"
   }

resource 'user-activemq',
    :cookbook => 'oneops.1.user',
    :design => true,
    :requires => {'constraint' => "1..1"},
    :attributes => {
      :username => 'activemq',
      :description => 'Activemq User',
      :home_directory => '/home/activemq',
      :system_account => true,
      :sudoer => true
}



# depends_on
[ {:from => 'activemq', :to => 'vol-data'},
  {:from => 'user-activemq', :to => 'os'},
  {:from => 'volume-externalstorage', :to => 'storage'},
  {:from => 'activemq', :to => 'volume-externalstorage'},
  {:from => 'activemq', :to => 'job'},
  {:from => 'activemq-daemon', :to => 'activemq'}].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
  :relation_name => 'DependsOn',
  :from_resource => link[:from],
  :to_resource => link[:to],
  :attributes => {"flex" => false, "min" => 1, "max" => 1}
end


[ 'activemq', 'keystore' ].each do |from|
  relation "#{from}::depends_on::java",
           :relation_name => 'DependsOn',
           :from_resource => from,
           :to_resource   => 'java',
           :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'keystore' ].each do |from|
  relation "#{from}::depends_on::certificate",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'certificate',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'activemq' ].each do |from|
  relation "#{from}::depends_on::keystore",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'keystore',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

['java', 'haproxy', 'vol-data','storage', 'activemq'].each do |from|

  relation "#{from}::depends_on::os",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'os',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end


[ 'build', 'artifact', 'configfile','activemq-daemon'].each do |from|
  relation "#{from}::depends_on::activemq",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'queue', 'topic' ].each do |from|
  relation "#{from}::depends_on::activemq",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

[ 'activemq-daemon' ].each do |from|
  relation "#{from}::depends_on::activemq",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

[ 'queue', 'topic' ].each do |from|
  relation "#{from}::depends_on::activemq-daemon",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'activemq-daemon',
    :attributes    => {"flex" => false, "min" => 1, "max" => 1 }
end

[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
['user-activemq', 'java', 'artifact','configfile', 'storage','build', 'keystore','haproxy', 'volume-externalstorage','activemq', 'vol-data', 'activemq-daemon'].each do |from|
  relation "#{from}::managed_via::compute",
  :except => ['_default'],
  :relation_name => 'ManagedVia',
  :from_resource => from,
  :to_resource => 'compute',
  :attributes => {}
end

