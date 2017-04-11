name             "Job"
description      "Job"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'description',
  :description => "Description",
  :format => {
    :help => 'Enter description for this scheduled job',
    :category => '1.Global',
    :order => 1
  }

attribute 'minute',
  :description => "Minute",
  :required => "required",
  :default => '0',
  :format => {
    :help => 'The minute this entry should run (0 - 59)',
    :category => '2.Schedule',
    :order => 1
  }

attribute 'hour',
  :description => "Hour",
  :required => "required",
  :default => '*',
  :format => {
    :help => 'The hour this entry should run (0 - 23)',
    :category => '2.Schedule',
    :order => 2
  }

attribute 'day',
  :description => "Day",
  :required => "required",
  :default => '*',
  :format => {
    :help => 'The day this entry should run (1 - 31)',
    :category => '2.Schedule',
    :order => 3
  }

attribute 'month',
  :description => "Month",
  :required => "required",
  :default => '*',
  :format => {
    :help => 'The month this entry should run (1 - 12)',
    :category => '2.Schedule',
    :order => 4
  }

attribute 'weekday',
  :description => "Weekday",
  :required => "required",
  :default => '*',
  :format => {
    :help => 'The weekday this entry should run (0 - 6) (Sunday=0)',
    :category => '2.Schedule',
    :order => 5
  }

attribute 'cmd',
  :description => "Command",
  :default => '/bin/true',
  :format => {
    :important => true,
    :help => 'The command to run',
    :category => '3.Command',
    :order => 1
  }

attribute 'user',
  :description => "User",
  :default => 'root',
  :format => {
    :help => 'The user to run command as',
    :category => '4.Options',
    :order => 1
  }

attribute 'variables',
  :description => "Variables",
  :data_type => 'hash',
  :default => '{"HOME":"","SHELL":"","MAILTO":"","PATH":""}',
  :format => {
    :help => 'Set the environment variables',
    :category => '4.Options',
    :order => 2
  }

recipe "repair", "Repair"
