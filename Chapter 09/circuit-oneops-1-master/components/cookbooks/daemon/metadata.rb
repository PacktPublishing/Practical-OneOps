name             "Daemon"
description      "Daemon/OS Level Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'service_name',
  :description => "Service Name",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Will be used to create init.d service: /etc/init.d/[service name]',
    :category => '1.Service',
    :order => 1
  }

attribute 'pattern',
  :description => "Process Table Pattern",
  :default => '',
  :format => {
    :important => true,
    :help => 'Optional regex to match for the process.  Use this to check the status of the process or enable the <b>Use control script status</b> below.',
    :category => '1.Service',
    :order => 2
  }
attribute 'use_script_status',
  :description => "Use Control Script Status",
  :default => 'true',
  :format => {
    :important => true,
    :help => 'Use the status from the script below versus the regex pattern above. Make sure the command will run as nagios user to get status.',
    :category => '1.Service',
    :order => 3,
    :form => { 'field' => 'checkbox' }
  }

attribute 'secondary_down',
          :description => 'Secondary Down',
          :default => 'false',
          :format => {
              :important => true,
              :help => "Monitor the secondary/standby daemon status and report 'up' if down or 'down' if up",
              :category => '1.Service',
              :order => 4,
              :form => {'field' => 'checkbox'}
          }

attribute 'control_script_location',
  :description => "Control Script Location",
  :format => {
    :help => 'Filename with path to init.d compliant control script control script. (It must support args: start,stop,restart,status.) We will create the file if it doesn\'t exist and sym-links from it to /etc/init.d/[service name]',
    :category => '2.Control Script',
    :order => 1
  }

attribute 'control_script_content',
  :description => "Control Script Content",
  :data_type => "text",
  :format => {
    :help => 'Set this if you want the content of the file to be overridden with this value. Must be init.d compliant control script.',
    :category => '2.Control Script',
    :order => 2
  }

recipe "status", "Daemon Status"
recipe "stop", "Stop Daemon"
recipe "start", "Start Daemon"
recipe "restart", "Restart Daemon"
recipe "repair", "Repair Daemon"
