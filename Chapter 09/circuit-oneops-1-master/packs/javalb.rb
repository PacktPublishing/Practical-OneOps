include_pack "java"
include_pack "genericlb"
ignore true

name "javalb"
description "Java With LB"
type "Platform"
category "Worker Application"


resource "lb",
  :except => [ 'single' ],
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "lb,dns" },
  :attributes => {
    "protocol"  => "tcp",
    "iprotocol" => "tcp",
    "vport"     => "8888",
    "iport"     => "8888"
  }

resource "secgroup",
   :design => true,
   :attributes => {
       "inbound" => '[ "22 22 tcp 0.0.0.0/0" ]'
   },
   :requires => {
       :constraint => "1..1",
       :services => "compute"
   } 

