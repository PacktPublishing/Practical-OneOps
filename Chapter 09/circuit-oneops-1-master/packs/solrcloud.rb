#
#
# Pack Name:: solrcloud
#
#

include_pack "genericlb"

name "solrcloud"
description "SolrCloud"
category "Search"
type    'Platform'

environment "single", {}
environment "redundant", {}

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

resource "java",
         :cookbook => "oneops.1.java",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => "*mirror",
             :help => "Java Programming Language Environment"
         },
         :attributes => {
             'flavor' => 'openjdk',
             'jrejdk' => 'jdk',
             'version' => '8'
         }

resource "artifact-app",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => { "constraint" => "0..*" }

resource 'volume-app',
         :cookbook => "oneops.1.volume",
         :requires => {'constraint' => '1..1', 'services' => 'compute'},
         :attributes => {'mount_point' => '/app/',
                         'size' => '100%FREE',
                         'device' => '',
                         'fstype' => 'ext4',
                         'options' => ''}

resource "solrcloud",
         :cookbook => "oneops.1.solrcloud",
         :design => true,
         :requires => { "constraint" => "1..1"},
         :monitors => {
          'solrprocess' => {
            :description => 'SolrProcess',
            :source => '',
            :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
            :cmd => 'check_solrprocess!:::node.workorder.rfcCi.ciAttributes.port_no:::',
            :cmd_line => '/opt/nagios/libexec/check_solrprocess.sh "$ARG1$"',
            :metrics => {
              'up' => metric(:unit => '%', :description => 'Percent Up'),
            },
            :thresholds => {
              'SolrProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
            }
          }
      }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {"inbound" => '[ "22 22 tcp 0.0.0.0/0","8080 8080 tcp 0.0.0.0/0","8983 8983 tcp 0.0.0.0/0" ]'},
         :requires => {
            :constraint => "1..1",
            :services => "compute"
         }

resource "tomcat-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :help => "Restarts Tomcat"
         },
         :attributes => {
            :service_name => 'tomcat7',
            :use_script_status => 'true',
            :pattern => ''
         },
         :monitors => {'tomcatprocess' => {
                        :description => 'TomcatProcess',
                        :source => '',
                        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                        :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::',
                        :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                        :metrics => {
                             'up' => metric(:unit => '%', :description => 'Percent Up'),
                        },
                        :thresholds => {
                            'TomcatDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                        }
                       }
                      }

resource "tomcat",
  :cookbook => "oneops.1.tomcat",
  :design => true,
  :requires => {
      :constraint => "0..*",
      :services=> "mirror" },
   :attributes => {
       'install_type' => 'binary',
       'tomcat_install_dir' => '/app',
       'webapp_install_dir' => '/app/tomcat7/webapps',
       'tomcat_user' => 'app',
       'tomcat_group' => 'app'
   },
  :monitors => {
      'HttpValue' => {:description => 'HttpValue',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_http_value!#{cmd_options[:url]}!#{cmd_options[:format]}',
                 :cmd_line => '/opt/nagios/libexec/check_http_value.rb $ARG1$ $ARG2$',
                 :cmd_options => {
                     'url' => '',
                     'format' => ''
                 },
                 :metrics => {
                     'value' => metric( :unit => '',  :description => 'value', :dstype => 'DERIVE'),
                     
                 }
       },  
        'Log' => {:description => 'Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logtomcat!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/log/apache-tomcat/catalina.out',
                     'warningpattern' => 'WARNING',
                     'criticalpattern' => 'CRITICAL'
                 },
                 :metrics => {
                     'logtomcat_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logtomcat_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logtomcat_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logtomcat_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                   'CriticalLogException' => threshold('15m', 'avg', 'logtomcat_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                 }
       },    
      'JvmInfo' =>  { :description => 'JvmInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_jvm',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb JvmInfo',
                  :metrics =>  {
                    'max'   => metric( :unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                    'free'   => metric( :unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                    'total'   => metric( :unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                    'percentUsed'  => metric( :unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE'),
                  },
                  :thresholds => {
                     'HighMemUse' => threshold('5m','avg','percentUsed',trigger('>',98,15,1),reset('<',98,5,1)),
                  }
                },
      'ThreadInfo' =>  { :description => 'ThreadInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_thread',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb ThreadInfo',
                  :metrics =>  {
                    'currentThreadsBusy'   => metric( :unit => '', :description => 'Busy Threads', :dstype => 'GAUGE'),
                    'maxThreads'   => metric( :unit => '', :description => 'Maximum Threads', :dstype => 'GAUGE'),
                    'currentThreadCount'   => metric( :unit => '', :description => 'Ready Threads', :dstype => 'GAUGE'),
                    'percentBusy'    => metric( :unit => 'Percent', :description => 'Percent Busy Threads', :dstype => 'GAUGE'),
                  },
                  :thresholds => {
                     'HighThreadUse' => threshold('5m','avg','percentBusy',trigger('>',90,5,1),reset('<',90,5,1)),
                  }
                },
      'RequestInfo' =>  { :description => 'RequestInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_request',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb RequestInfo',
                  :metrics =>  {
                    'bytesSent'   => metric( :unit => 'B/sec', :description => 'Traffic Out /sec', :dstype => 'DERIVE'),
                    'bytesReceived'   => metric( :unit => 'B/sec', :description => 'Traffic In /sec', :dstype => 'DERIVE'),
                    'requestCount'   => metric( :unit => 'reqs /sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                    'errorCount'   => metric( :unit => 'errors /sec', :description => 'Errors /sec', :dstype => 'DERIVE'),
                    'maxTime'   => metric( :unit => 'ms', :description => 'Max Time', :dstype => 'GAUGE'),
                    'processingTime'   => metric( :unit => 'ms', :description => 'Processing Time /sec', :dstype => 'DERIVE')                                                          
                  },
                  :thresholds => {
                  }
                }
}

resource "library",
         :cookbook => "oneops.1.library",
         :design => true,
         :requires => { "constraint" => "1..*" },
         :attributes => {
           "packages"  => '["bc"]'
         }

# depends_on
[
 {:from => 'solrcloud', :to => 'os'},
 {:from => 'solrcloud', :to => 'user-app'},
 {:from => 'user-app', :to => 'os'},
 {:from => 'tomcat-daemon', :to => 'tomcat'},
 {:from => 'os', :to => 'compute'},
 {:from => 'java', :to => 'os'},
 {:from => 'volume-app', :to => 'os'},
 {:from => 'solrcloud', :to => 'volume-app'},
 {:from => 'artifact-app', :to => 'volume-app'},
 {:from => 'volume-app', :to => 'os'},
 {:from => 'solrcloud', :to => 'tomcat'},
 {:from => 'solrcloud', :to => 'tomcat-daemon'},
 {:from => 'tomcat', :to => 'java'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "solrcloud::depends_on::tomcat",
  :relation_name => 'DependsOn',
  :from_resource => 'solrcloud',
  :to_resource => 'tomcat',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

# managed_via
[ 'tomcat','tomcat-daemon','solrcloud', 'file','user-app', 'java', 'volume-app', 'artifact-app'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
