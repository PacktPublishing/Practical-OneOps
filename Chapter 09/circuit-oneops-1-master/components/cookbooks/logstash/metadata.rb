name             "Logstash"
description      "Logstash"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "1.5.3",
  :format => {
    	:important => true,
        :help => 'Version of Logstash',
        :category => '1.Global',
        :order => 1,
        :form => {'field' => 'select', 'options_for_select' => [['1.5.3', '1.5.3'], ['1.4.2', '1.4.2'], ['1.5.0.rc2', '1.5.0.rc2'], ['1.5.0.rc3', '1.5.0.rc3'], ['1.5.0', '1.5.0'], ['2.1.3', '2.1.3'], ['2.2.2','2.2.2'], ['2.2.4', '2.2.4'], ['2.3.4', '2.3.4']]},
        :pattern => "[0-9\.]+"
  }

attribute 'inputs',
  :description => "Inputs",
  :data_type => "array",
  :required => "required",
  :format => { 
    :help => 'Input config. Must be in logstash defined format.Example inputs can be lumberjack, file, syslog etc',
    :category => '2.Inputs',
    :order => 1
  }
  
attribute 'filters',
  :description => "Filters",
  :data_type => "array",
  :format => { 
    :help => 'Filters for log processing. Must be in logstash defined format.Example filters can be grok, date etc',
    :category => '3.Filters',
    :order => 1
  }
  
attribute 'outputs',
  :description => "Outputs",
  :data_type => "array",
  :required => "required",
  :format => { 
    :help => 'Output config. Must be in logstash defined format.Example outputs can be elasticsearch, statsd etc',
    :category => '4.Outputs',
    :order => 1
  }    
  
recipe "status", "Logstash Status"
recipe "stop", "Stop Logstash"
recipe "start", "Start Logstash"
recipe "restart", "Restart Logstash"
recipe "repair", "Repair Logstash"
