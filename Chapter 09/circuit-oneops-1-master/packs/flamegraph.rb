include_pack  "tomcat"
name          "flamegraph"
description   "FlameGraph"
type          "Platform"
category      "Web Application"

resource "nginx",
	:cookbook => "oneops.1.nginx",
	:design => true,
	:requires => { "constraint" => "1..1" },
	:attributes => { "version"  => "8.4" },
	:monitors => {
		'nginx-status' =>  { :description => 'BuiltIn Nginx Status',
			:source => '',
			:chart => {'min'=>0, 'unit'=>'Seconds'},
			:cmd => 'check_nginx_status',
			:cmd_line => '/opt/nagios/libexec/check_nginx.rb',
			:metrics =>  {
				'active_connections'   => metric( :unit => '', :description => 'Active Connections', :dstype => 'GAUGE'),
				'acceped'   => metric( :unit => 'PerSecond', :description => 'Accepted Reqs', :dstype => 'DERIVE'),
				'handled'   => metric( :unit => 'PerSecond', :description => 'Handled Reqs', :dstype => 'DERIVE'),
				'reading'   => metric( :unit => '', :description => 'Reading', :dstype => 'GAUGE'),
				'writing'   => metric( :unit => '', :description => 'Writing', :dstype => 'GAUGE'),
				'waiting'   => metric( :unit => '', :description => 'Waiting', :dstype => 'GAUGE')
				},
				:thresholds => {
				}
		}
	}	


resource "secgroup",
	 :cookbook => "oneops.1.secgroup",
	 :design => true,
	 :attributes => {
	 	"inbound" => '[ "22 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0", "8009 8009 tcp 0.0.0.0/0", "8443 8443 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0" ]'
         },
         :requires => {
	 :constraint => "1..1",
	 	:services => "compute"
	 }


resource "build",
	  :cookbook => "oneops.1.build",
	  :design => true,
	  :requires => { "constraint" => "0..*" },
	  :attributes => {
	  	"install_dir"   => '/usr/local/build',
	        "repository"    => "",
		"remote"        => 'origin',
		"revision"      => 'HEAD',
		"depth"         => 1,
		"submodules"    => 'false',
		"environment"   => '{}',
		"persist"       => '[]',
		"migration_command" => '',
		"restart_command"   => ''
	}

resource "website",
	  :cookbook => "oneops.1.website",
	  :design => true,
	  :requires => { "constraint" => "1..*" },
	  :attributes => {
	  	"server_name"   => "",
	  	"port"          => "80",
	  	"root"          => "",
	  	"index"         => "index.html",
	  	"extra"         => <<-eos
eos
  },
	:monitors => {
	  	'Url' =>  { :description => 'Url Monitor',
	  	:source => '',
	  	:chart => {'min'=>0, 'unit'=>''},
	  	:cmd => 'check_website',
          	:cmd_line => '/opt/nagios/libexec/check_http -H localhost',
	  	:metrics =>  {
	        	'time'   => metric( :unit => '', :description => 'Response Time', :dstype => 'GAUGE'),
			'size'   => metric( :unit => '', :description => 'Size', :dstype => 'GAUGE')
                },
		:thresholds => {
			'SlowWebsite' => threshold('5m','avg','time',trigger('>',1,5,1),reset('<',1,5,1)),
		}
		}
  	}

resource "flamegraph" ,
	:cookbook => "oneops.1.flamegraph",
	#:source => Chef::Config[:register],
	:design => true,
	:requires => {"constraint" => "1..1"},
	:attributes => {
		'perf_record_seconds' =>  '100',
		'perf_record_freq' => '99',
		'perf_java_tmp' => "/tmp",
		'perf_data_file' => "perf-out",
		'perf_flame_output' => "flamegraph-`date '+%Y-%m-%d-%H-%M'`.svg",
		'flamegraph_dir' => "/tmp/flamegraph_src",
		'app_user' => 'app',
	}


resource "tomcat",
         :cookbook => "oneops.1.tomcat",
         :design => true,
         :requires => {
			 :constraint => "1..1",
			 :services => "mirror"
			 },
         :attributes => {
             'install_type' => 'binary',
	     :services=> "mirror",
             'tomcat_install_dir' => '/app',
             'version' => '7.0',
             'build_version' => '62',
             'webapp_install_dir' => '/app/tomcat7/webapps',
             'java_options' => '-Djava.awt.headless=true -verbose:gc',
             'tomcat_user' => 'app',
             'tomcat_group' => 'app',
             'startup_params' => '[
		    "+PreserveFramePointer"
                  ]',
             'mem_max' => '1024m',
             'mem_start' => '512m',
#             'checksum' => 'c163f762d7180fc259cc0d8d96e6e05a53b7ffb0120cb2086d6dfadd991c36df',
             'access_log_dir' =>'/log/apache-tomcat',
             'access_log_pattern'=>'%h %{NSC-Client-IP}i %l %u %t &quot;%r&quot; %s %b %D %F'
	},
         :monitors => {
             'JvmInfo' => {:description => 'JvmInfo',
                           :source => '',
                           :chart => {'min' => 0, 'unit' => ''},
                           :cmd => 'check_tomcat_jvm',
                           :cmd_line => '/opt/nagios/libexec/check_tomcat.rb JvmInfo',
                           :metrics => {
                               'max' => metric(:unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                               'free' => metric(:unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                               'total' => metric(:unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                               'percentUsed' => metric(:unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE'),
                           },
                           :thresholds => {
                              'HighMemUse' => threshold('1m','avg', 'percentUsed',trigger('>=',95,5,1),reset('<',90,5,1)),
                           }
             },
             'ThreadInfo' => {:description => 'ThreadInfo',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_tomcat_thread',
                              :cmd_line => '/opt/nagios/libexec/check_tomcat.rb ThreadInfo',
                              :metrics => {
                                  'currentThreadsBusy' => metric(:unit => '', :description => 'Busy Threads', :dstype => 'GAUGE'),
                                  'maxThreads' => metric(:unit => '', :description => 'Maximum Threads', :dstype => 'GAUGE'),
                                  'currentThreadCount' => metric(:unit => '', :description => 'Ready Threads', :dstype => 'GAUGE'),
                                  'percentBusy' => metric(:unit => 'Percent', :description => 'Percent Busy Threads', :dstype => 'GAUGE'),
                              },
                              :thresholds => {
                                 'HighThreadUse' => threshold('5m','avg','percentBusy',trigger('>=',90,5,1),reset('<',85,5,1)),
                              }
             },
             'RequestInfo' => {:description => 'RequestInfo',
                               :source => '',
                               :chart => {'min' => 0, 'unit' => ''},
                               :cmd => 'check_tomcat_request',
                               :cmd_line => '/opt/nagios/libexec/check_tomcat.rb RequestInfo',
                               :metrics => {
                                   'bytesSent' => metric(:unit => 'B/sec', :description => 'Traffic Out /sec', :dstype => 'DERIVE'),
                                   'bytesReceived' => metric(:unit => 'B/sec', :description => 'Traffic In /sec', :dstype => 'DERIVE'),
                                   'requestCount' => metric(:unit => 'reqs /sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                                   'errorCount' => metric(:unit => 'errors /sec', :description => 'Errors /sec', :dstype => 'DERIVE'),
                                   'maxTime' => metric(:unit => 'ms', :description => 'Max Time', :dstype => 'GAUGE'),
                                   'processingTime' => metric(:unit => 'ms', :description => 'Processing Time /sec', :dstype => 'DERIVE')
                               },
                               :thresholds => {
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
             } ,
             'AppVersion' => {:description => 'AppVersion',
                       :source => '',
                       :enable => 'false',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_tomcat_app_version',
                       :cmd_line => '/opt/nagios/libexec/check_tomcat_app_version.sh',
                       :metrics => {
                           'versionlatest' => metric(:unit => '', :description => 'value=0; App version is latest', :dstype => 'GAUGE'),
                       },
                       :thresholds => {
                         'VersionIssue' => threshold('1m', 'avg', 'versionlatest', trigger('>', 0, 5, 4), reset('<=', 0, 1, 1)),
 					}
             }
         }


resource "user-app",
	:cookbook => "oneops.1.user",
	:design => true,
	:requires => {"constraint" => "1..1"},
	:attributes => {
	    "username" => "app",
	    "description" => "App User",
	    "home_directory" => "/app",
	    "system_account" => true,
	    "sudoer" => true
	}


resource "java",
				 :cookbook => "oneops.1.java",
				 :design => true,
				 :requires => {
						 :constraint => "1..1",
						 :services => "mirror",
						 :help => "Java Programming Language Environment"
				 },
				 :attributes => {
						 :install_dir => "/usr/lib/jvm",
						 :flavor => "oracle",
						 :jrejdk => "jdk",
						 :version => "8",
						 :uversion => "66",
						 :binpath => "",
						 :sysdefault => "true"
				 }

# depends_on
[ { :from => 'nginx',  :to => 'compute' },
	{ :from => 'nginx',  :to => 'library' },
        { :from => 'nginx',  :to => 'os' },
        {:from => 'user-app', :to => 'os'},
        {:from => 'flamegraph', :to => 'user-app'},
        {:from => 'tomcat', :to => 'user-app'},
	{ :from => 'build',   :to => 'nginx'  },
	{ :from => 'website', :to => 'nginx'  },
        { :from => 'website', :to => 'build'   },
	{ :from => 'flamegraph',  :to => 'tomcat' }].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# managed_via
[ 'user-app', 'nginx', 'build', 'website', 'flamegraph' ].each do |from|
	relation "#{from}::managed_via::compute",
		:except => [ '_default' ],
		:relation_name => 'ManagedVia',
		:from_resource => from,
		:to_resource   => 'compute',
		:attributes    => { }
end

