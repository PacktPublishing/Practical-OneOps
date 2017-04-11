name             "Download"
description      "Downloads external files or directories"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends          "shared"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'source',
  :description => "Source URL",
  :required => "required",
  :format => {
    :important => true,
    :help => 'Specify remote URL location (ex. http://site/file or s3://bucket/file',
    :category => '1.Source',
    :order => 1
  }

attribute 'basic_auth_user',
  :description => "Basic Auth User",
  :format => {
    :help => 'Basic authentication username for URLs or Access Key for S3',
    :category => '1.Source',
    :order => 2
  }

attribute 'basic_auth_password',
  :description => "Basic Auth Password",
  :encrypted => true,
  :format => {
    :help => 'Basic authentication password or Secret Key for S3',
    :category => '1.Source',
    :order => 3
  }

attribute 'headers',
  :description => "Custom Headers",
  :data_type => "hash",
  :format => {
    :help => 'Additional HTTP headers',
    :category => '1.Source',
    :order => 4
  }

attribute 'checksum',
  :description => "Checksum",
  :format => {
    :help => 'Optional checksum to verify against the downloaded attachment',
    :category => '1.Source',
    :order => 5
  }

attribute 'path',
  :description => "Destination Filename",
  :required => "required",
  :default => '/tmp/download_file',
  :format => {
    :important => true,
    :help => 'Specify destination filename path where the downloaded file will be saved',
    :category => '2.Destination',
    :order => 1
  }

attribute 'post_download_exec_cmd',
  :description => "Execute Command",
  :format => {
    :help => 'Optional command to execute after download',
    :category => '3.Run',
    :order => 1
  }

recipe "repair", "Repair"
