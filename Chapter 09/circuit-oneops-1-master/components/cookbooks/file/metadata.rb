name             "File"
description      "Custom file"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'content',
  :description => "Content",
  :data_type => "text",
  :format => {
    :help => 'Use this field to directly specify content such as a script, configuration file, certificate etc',
    :category => '1.Content',
    :order => 1
  }

attribute 'path',
  :description => "Destination Path",
  :required => "required",
  :default => '/tmp/download_file',
  :format => {
    :important => true,
    :help => 'Specify destination filename path where the file will be saved',
    :category => '2.Destination',
    :order => 1
  }

attribute 'exec_cmd',
  :description => "Execute Command",
  :format => {
    :help => 'Optional commands to execute after downloading the file from remote source and/or saving the included file content',
    :category => '3.Run',
    :order => 1
  }

recipe "repair", "Repair"
