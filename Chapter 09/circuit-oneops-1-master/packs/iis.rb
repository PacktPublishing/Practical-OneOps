include_pack "genericlb"

name "iis"
description "Internet Information Services(IIS)"
type "Platform"
category "Web Application"

environment "single", {}
environment "redundant", {}

variable "platform_deployment",
  :description => 'Downloads the nuget packages',
  :value       => 'e:\platform_deployment'

variable "app_directory",
  :description => 'Application directory',
  :value       => 'e:\apps'

variable "nuget_exe",
  :description => 'Nuget exe path',
  :value       => 'C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools\NuGet.exe'

variable "log_directory",
  :description => 'Log directory',
  :value       => 'e:\logs'

variable "drive_name",
  :description => 'drive name',
  :value       => 'E'

resource "compute",
         :attributes => {"size" => "M-WIN"}

resource "iis-website",
  :cookbook     => "oneops.1.iis-website",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs/Configure IIS"
  },
  :attributes   => {
    "physical_path" => '$OO_LOCAL{app_directory}',
    "log_file_directory" => '$OO_LOCAL{log_directory}',
    "dc_file_directory" => '$OO_LOCAL{log_directory}\\IISTemporaryCompressedFiles',
    "sc_file_directory" => '$OO_LOCAL{log_directory}\\IISTemporaryCompressedFiles'
  }

resource "dotnetframework",
  :cookbook     => "oneops.1.dotnetframework",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs .net frameworks",
    :services   => '*mirror'
  },
  :attributes   => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/',
    "dotnet_version_package_name" => '{ ".Net 4.6":"dotnet4.6", ".Net 3.5":"dotnet3.5" }'
  }

nuget_package_configure_cmd=  <<-"EOF"

nuget = '$OO_LOCAL{nuget_exe}'
package_name = node.artifact.repository
depends_on = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /website/ }
physical_path = depends_on.first[:ciAttributes][:physical_path]
site_name = node.workorder.box.ciName
package_physical_path = ::File.join(physical_path, package_name)
website_physical_path = ::File.join(physical_path, site_name)

[package_physical_path, website_physical_path].each do |path|
  directory path do
    action :delete
    recursive true
  end
end

powershell_script "Install package #\{package_name\}" do
  code "#\{nuget\} install #\{package_name\} -Source #\{artifact_cache_version_path\} -outputdirectory #\{physical_path\} -ExcludeVersion -NoCache"
end

powershell_script "Renaming package folder #\{package_physical_path\} to #\{site_name\}" do
  guard_interpreter :powershell_script
  code "Rename-Item #\{package_physical_path\} #\{site_name\}"
  not_if "Test-Path #\{website_physical_path\}"
end


EOF

chocolatey_package_configure_cmd=  <<-"EOF"

package_name = node.artifact.repository
file_extension = File.extname(node.artifact.location)
uri = URI.parse(node.artifact.location)
file_name = File.basename(uri.path)
file_physical_path = ::File.join(artifact_cache_version_path, file_name)

if file_extension != 'nupkg' && File.exist?(file_physical_path)
 package_location = ::File.join(artifact_cache_version_path, "#\{package_name\}.nupkg")
 ::File.rename(file_physical_path,package_location)
end

chocolatey_package package_name do
  source artifact_cache_version_path
  options "--ignore-package-exit-codes=3010"
  action :install
end

EOF

resource "chocolatey-package",
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => "0..*",
    :help        => "Installs chocolatey package"
  },
  :attributes       => {
     :repository    => '',
     :location      => '',
     :install_dir   => '$OO_LOCAL{platform_deployment}',
     :as_user       => 'oneops',
     :as_group      => 'oneops',
     :should_expand => 'false',
     :configure     => chocolatey_package_configure_cmd,
     :migrate       => '',
     :restart       => ''
}


resource "nuget-package",
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => "1..*",
    :help        => "Installs nuget package"
  },
  :attributes       => {
     :repository    => '',
     :location      => '',
     :install_dir   => '$OO_LOCAL{platform_deployment}',
     :as_user       => 'oneops',
     :as_group      => 'oneops',
     :should_expand => 'true',
     :configure     => nuget_package_configure_cmd,
     :migrate       => '',
     :restart       => ''
  },
  :payloads => {
    'iis-website' => {
      'description' => 'iis-website',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Artifact",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Iis-website"
           }
         ]
      }'
    }
  }

resource "secgroup",
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0"]'
  }

resource "os",
  :attributes => {
    "ostype"  => "windows_2012_r2"
  }

resource "volume",
  :requires       => {
    :constraint   => "1..1"
  },
  :attributes     => {
    "mount_point" => '$OO_LOCAL{drive_name}'
  }

[ { :from => 'iis-website', :to => 'dotnetframework' },
  { :from => 'dotnetframework', :to => 'os' },
  { :from => 'chocolatey-package', :to => 'volume' },
  { :from => 'nuget-package', :to => 'iis-website' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "iis-website::depends_on::certificate",
  :relation_name => 'DependsOn',
  :from_resource => 'iis-website',
  :to_resource => 'certificate',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

[ 'iis-website', 'nuget-package', 'dotnetframework', 'chocolatey-package' , 'volume', 'os' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
