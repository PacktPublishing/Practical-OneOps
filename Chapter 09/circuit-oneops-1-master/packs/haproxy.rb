include_pack "custom"

name "haproxy"
description "Haproxy"
type "Platform"
category "Infrastructure Service"

environment "single", {}
environment "redundant", {}
#environment "ha", {}

resource "haproxy",
  :cookbook => "oneops.1.haproxy",
  :design => true,
  :requires => { "constraint" => "1..1" },
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
[ { :from => 'haproxy',  :to => 'os' },
  { :from => 'haproxy',  :to => 'library' },
  { :from => 'haproxy',  :to => 'download' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 } 
end


# managed_via
[ 'haproxy' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end
