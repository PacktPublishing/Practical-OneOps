include_pack "base"

name "squid"
description "Squid"
type "Platform"
category "Content Caching"

platform :attributes => {'autoreplace' => 'false'}

resource "squid",
  :cookbook => "oneops.1.squid",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "This is an HTML help text for squid component"
  },
  :attributes => {
    "install_type" => '3.3.8',
    "acl_values" => '[]',
    "http_access_allow" => '[]',
    "http_access_deny" => '[]',
    "port" => '80',
    "cache_dir" => '/cache',
    "cache_mem" => '1024',
    "cache_size" => '8092',
    "maximum_object_size" => '512',
    "dns_server_list" => ''
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
                       'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false),
                       'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE')
                   },
                   :thresholds => {

                   }
         }
}

resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/cache',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
                 }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }


# depends_on
[ { :from => 'squid',  :to => 'os' },
  { :from => 'volume',  :to => 'os' },
  { :from => 'squid',  :to => 'volume' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
[ 'squid' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
