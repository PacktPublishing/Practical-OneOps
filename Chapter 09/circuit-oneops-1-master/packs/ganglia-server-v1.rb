include_pack "base"

name "ganglia-server-v1"
description "Ganglia Server (v1 Build)"
type "Platform"
category "Monitoring"

# Versioning attributes
ganglia_version = "1"
ganglia_server_cookbook = "oneops.1.ganglia-server-v#{ganglia_version}"
# When changing version, need to change the class name in payload definitions.

platform :attributes => {'autoreplace' => 'false'}

resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
           # Port configuration:
           #
           #  null:  Ping
           #    22:  SSH
           #    80:  Ganglia Server
           # 8800-8899: Server gmond instances
           # 60000:  For mosh
           #
           "inbound" => '[
               "null null 4 0.0.0.0/0",
               "22 22 tcp 0.0.0.0/0",
               "80 80 tcp 0.0.0.0/0",
               "8800 8899 udp 0.0.0.0/0",
               "8800 8899 tcp 0.0.0.0/0",
               "60000 60100 udp 0.0.0.0/0"
           ]'
         },
         :requires   => {
           :constraint => '1..1',
           :services   => 'compute'
         }

#resource 'ring',
#         :except   => ['single'],
#         :cookbook => 'oneops.1.ring',
#         :design   => false,
#         :requires => {:constraint => '1..1'},
#         :payloads => {
#         }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => { "constraint" => "0..*" },
         :attributes => {

         },
         :monitors => {
             'URL' => {:description => 'URL',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
                       :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
                       :cmd_options => {
                           'host' => 'localhost',
                           'port' => '80',
                           'url' => '/',
                           'wait' => '15',
                           'expect' => '200 OK',
                           'regex' => ''
                       },
                       :metrics => {
                           'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
                           'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
                           'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
                       },
                       :thresholds => {

                       }
             },
             'exceptions' => {:description => 'Exceptions',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                              :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                              :cmd_options => {
                                  'logfile' => '/log/logmon/logmon.log',
                                  'warningpattern' => 'Exception',
                                  'criticalpattern' => 'Exception'
                              },
                              :metrics => {
                                  'logexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                                  'logexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                                  'logexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                                  'logexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                              },
                              :thresholds => {
                                  'CriticalExceptions' => threshold('15m', 'avg', 'logexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
                              }
             }
         }

resource 'ganglia-server',
         :cookbook   => ganglia_server_cookbook,
#         :source => Chef::Config[:register],
         :design     => true,
         :attributes => {
         },
#         :requires   => {
#           :constraint => '1..1',
#           :services => '*maven',
#           :help       => 'Ganglia Server'
#         },
         :monitors => {
           'CheckGMeta' => {
             :description => 'Ganglia Metaserver Process',
             :source      => '',
             :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
             :cmd         => 'check_process!gmetad!true!none',
             :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
             :metrics     => {
               'up' => metric(:unit => '%', :description => 'Percent Up'),
             },
             :thresholds  => {
               'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
             }
           }
         },
         :payloads => {
         }

# depends_on
[ { :from => 'ganglia-server', :to => 'os' },
  { :from => 'daemon',    :to => 'artifact'  }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "fqdn::depends_on::compute",
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }

#relation "ring::depends_on::ganglia-server",
#    :except => [ '_default', 'single' ],
#    :relation_name => 'DependsOn',
#    :from_resource => 'ring',
#    :to_resource   => 'ganglia-server',
#    :attributes    => { :propagate_to => 'from', "flex" => true, "min" => 1, "max" => 10 }

#relation 'fqdn::depends_on::ring',
#         :except        => ['_default', 'single'],
#         :relation_name => 'DependsOn',
#         :from_resource => 'fqdn',
#         :to_resource   => 'ring',
#         :attributes    => {:propagate_to => 'from', :flex => false, :min => 1, :max => 1}

#relation 'fqdn::depends_on::compute',
#         :only          => ['_default', 'single'],
#         :relation_name => 'DependsOn',
#         :from_resource => 'fqdn',
#         :to_resource   => 'compute',
#         :attributes    => {:flex => false, :min => 1, :max => 1}

['ganglia-server', 'artifact'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

#relation 'ring::managed_via::compute',
#         :except        => ['_default', 'single'],
#         :relation_name => 'ManagedVia',
#         :from_resource => 'ring',
#         :to_resource   => 'compute',
#         :attributes    => {}

## securedBy
#['ring'].each do |from|
#  relation "#{from}::secured_by::sshkeys",
#           :except        => ['_default', 'single'],
#           :relation_name => 'SecuredBy',
#           :from_resource => from,
#           :to_resource   => 'sshkeys',
#           :attributes    => {}
#end
