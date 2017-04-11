name               'Golang'
description        'Golang Platform and Application Installation'
long_description   IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version            '1.0'
maintainer         '@WalmartLabs'
maintainer_email   'hburma1@email.wal-mart.com'
license            'Copyright Walmart, All rights reserved.'

grouping 'default',
         :access => "global",
	 :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'mgmt.cloud.service', 'cloud.service', 'bom'],
	 :namespace => true


attribute 'go_from_source',
  :description => "Go Installation Type",
  :required => "required",
  :default => "false",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Select the type of installation - standard OS repository package or custom build from source code',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['From_Source','true'],['From_Binary','false']] }
  }

attribute 'go_version',
  :description => "Go Version",
  :required => "required",
  :default => "1.5",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Version to Install',
    :order => 2
  }

attribute 'go_install_dir',
  :description => "Go Install Dir",
  :required => "required",
  :default => "/usr/local",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Install Directory',
    :order => 3
  }

attribute 'gopath',
  :description => "Go Path",
  :required => "required",
  :default => "/opt/go",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Path',
    :order => 4
  }

attribute 'gobin',
  :description => "Go Bin Path",
  :required => "required",
  :default => "/opt/go/bin",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Binary Path',
    :order => 5
  }

attribute 'go_scm',
  :description => "Go SCM",
  :required => "required",
  :default => "true",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go SCM to Install',
    :order => 6,
    :form => { 'field' => 'select', 'options_for_select' => [['True','true'],['False','false']] }
  }

attribute 'go_packages',
  :description => "Go Packages",
  :default => '[]',
  :data_type => 'array',
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Packages To Install',
    :order => 7
  }

attribute 'go_owner',
  :description => "Go Owner",
  :required => "required",
  :default => "root",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Owner',
    :order => 8
  }

 attribute 'go_group',
  :description => "Go Group",
  :required => "required",
  :default => "root",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Group',
    :order => 9
  }

attribute 'go_download_url',
  :description => "Go Download URL",
  :required => "required",
  :default => "http://golang.org/dl/",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Download URL',
    :order => 10
  }

attribute 'go_source_method',
  :description => "Go Source Method",
  :required => "required",
  :default => "all.bash",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Download URL',
    :order => 11,
    :filter => {'all' => {'visible' => 'go_from_source:eq:true'}}
  }

 attribute 'go_mode',
  :description => "Go Mode",
  :required => "required",
  :default => "0755",
  :format => {
    :category => '1.GO_Specifics',
    :help => 'Go Mode',
    :order => 12
  }

attribute 'artifact_type',
  :description => "Artifact Type",
  :required => "required",
  :default => "build",
  :format => {
    :category => '2.Artifact_Detils',
    :help => 'Go Artifact to Install',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['Build','build'],['Binary','binary']] }
  }

attribute 'artifact_link_type',
  :description => "Artifact Link Type Git/Tar",
  :required => "required",
  :default => "non-git",
  :format => {
    :category => '2.Artifact_Detils',
    :help => 'Go Artifact Link Type Git/Tar',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [['Git','git'],['TarBall','non-git']] }
  }

attribute 'artifact_link',
  :description => "Artifact Link",
  :required => "required",
  :default => "",
  :format => {
    :category => '2.Artifact_Detils',
    :help => 'Go Artifact Link',
    :order => 3
  }

attribute 'artifact_git_revision',
  :description => "Artifact Git Revison",
  :required => "required",
  :default => "master",
  :format => {
    :category => '2.Artifact_Detils',
    :help => 'Go Artifact to Install',
    :order => 4,
    :filter => {'all' => {'visible' => 'artifact_link_type:eq:git'}}
  }

attribute 'source_name',
  :description => "Application Source Name",
  :required => "required",
  :default => "",
  :format => {
    :category => '2.Artifact_Detils',
    :help => 'Go Source Name',
    :order => 5
  }

attribute 'app_version',
  :description => "Application Release Version",
  :required => "required",
  :default => "",
  :format => {
    :category => '3.Application_Version',
    :help => 'Application Version',
    :order => 1
  }

attribute 'app_cmdline_options',
  :description => "Application Command Line Options",
  :default => "", 
  :format => { 
    :category => '3.Application_Version',
    :help => 'Application Command Line Options',
    :order => 2
  } 

attribute 'app_dir',
  :description => "Application Directory",
  :default => "/app",
  :format => {
    :category => '3.Application_Version',
    :help => 'Application Directory',
    :order => 3
  }

attribute 'app_user',
  :description => "Application User",
  :default => "app",
  :format => {
    :category => '3.Application_Version',
    :help => 'Application User',
    :order => 4
  }
