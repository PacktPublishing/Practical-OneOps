include_pack "genericlb"

name          "golang"
description   "GoLang Application"
type          "Platform"
category      "Worker Application"


variable "name",
	:description => 'Application Name',
	:value => ''

variable "domain",
	:description => 'Application domain (app.domain)',
	:value => ''

variable "groupId",
	:description => 'Group Identifier',
	:value => ''

variable "artifactId",
	:description => 'Artifact Identifier',
	:value => ''

variable "appVersion",
	:description => 'Artifact Version',
	:value => ''

variable "extension",
	:description => 'Artifact Extension',
	:value => ''

variable "repository",
	:description => 'Repository Name',
	:value => ''

variable "shaVersion",
	:description => 'Artifact Download Checksum',
	:value => ''


resource "golang",
	:cookbook => "oneops.1.golang",
	:design	=> true,
	:requires => {"constraint" => "1..1"},
	:attributes => {
		"go_version" => "1.5",
		"go_platform" => "amd64",
		"go_from_source" => false,
		"go_install_dir" => "/usr/local",
		"gopath" => "/opt/go",
		"gobin" => "/opt/go/bin",
		"go_scm" => true,
		"go_mode" => '0755',
		"go_packages" => '[]',
		"go_owner" => "root",
		"go_group" => "root",
		"artifact_type" => "build",
		"artifact_id" => "$OO_LOCAL{artifactId}",
		"app_version" => "0.1",
		"artifact_link" => "https://github.com/oneops/samples/raw/master/golang_app/server.tar",
		"source_name" => "server",
		"app_cmdline_options" => ""
	}


resource "user-app",
	:cookbook => "oneops.1.user",
	:design => true,
	:requires => {"constraint" => "1..1"},
	:attributes => {
	    "username" => "app",
	    "description" => "App User",
	    "home_directory" => "/app",
	    "system_account" => true,
	    "sudoer" => true
	}

resource "go-artifact",
	:cookbook => "oneops.1.artifact",
	:design => true,
	:requires => {
	    :constraint => "0..*",
	    :services => "maven",
	    :help => "A tar artifact which should contain the Go binary with any other files as needed"
	},
	:attributes => {
	    :url => '$OO_CLOUD{nexus}',
	    :repository => '$OO_LOCAL{repository}',
	    :username => '',
	    :password => '',
	    :location => '$OO_LOCAL{groupId}:$OO_LOCAL{artifactId}:$OO_LOCAL{extension}',
	    :version => '$OO_LOCAL{appVersion}',
	    :checksum => '$OO_LOCAL{shaVersion}',
	    :install_dir => '/app/$OO_LOCAL{artifactId}',
	    :as_user => 'app',
	    :as_group => 'app',
	    :environment => '{}',
	    :persist => '[]',
	    :should_expand => 'true',
	    :configure => "directory \"/log/logmon\" do \n  owner \'app\' \n  group \'app\' \n  action :create \nend", 
	    :migrate => '',
	    :restart => "execute \"find /app/$OO_LOCAL{artifactId} -type f -name \'*$OO_LOCAL{artifactId}*\' -exec chmod 777 {} \\\\;\""
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

resource "volume-app",
	:cookbook => "oneops.1.volume",
	:design => true,
	:requires => { "constraint" => "1..1", "services" => "compute" },
	:attributes => {  "mount_point"   => '/app',
	    "size"          => '10G',
	    "device"        => '',
	    "fstype"        => 'ext4',
	    "options"       => ''
	},
	:monitors => {
	    'usage' =>  {'description' => 'Usage',
	        'chart' => {'min'=>0,'unit'=> 'Percent used'},
	        'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
	        'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
	        'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
	            'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
	        :thresholds => {
	            'LowDiskSpace' => threshold('1m','avg','space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
	            'LowDiskInode' => threshold('1m','avg','inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
	          },
	    }
}

# depends_on
[{:from => 'volume-app', :to => 'os'},
{:from => 'user-app', :to => 'os'},
{:from => 'golang', :to => 'os'},
{:from => 'golang', :to => 'user-app'},
{:from => 'go-artifact', :to => 'golang'},
{:from => 'daemon', :to => 'go-artifact'},
{:from => 'go-artifact', :to => 'volume-app'}].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# managed_via
['user-app', 'go-artifact', 'library', 'volume-app', 'golang'].each do |from|
    relation "#{from}::managed_via::compute",
    :except => ['_default'],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource => 'compute',
    :attributes => {}
end
