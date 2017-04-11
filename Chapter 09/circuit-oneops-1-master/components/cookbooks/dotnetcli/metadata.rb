name             'Dotnetcli'
description      'Installs/Configures .NET CLI'
version          '0.1.0'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          '.NET CLI'


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]
attribute 'folderpath',
  :description => 'Dotnet Installation Folder',
  :default => '/opt/dotnet',
  :format => {
    :help => 'Default name of the file to create',
    :category => '1.Global',
    :order => 1
  }


  # operating system
  attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-7.0",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '1.Global',
    :order => 2,
    :form => { 'field' => 'select', 'options_for_select' => [
    ['CentOS 7.0','centos-7.0'],['Ubuntu 14.04','ubuntu-14.04']]
  }
  }

  attribute 'src_url',
            :description => 'Source URL',
            :required => 'required',
            :default => 'https://go.microsoft.com/fwlink/?LinkID=809131',
            :format => {
                :help => 'location of the dotnet source distribution',
                :category => '1.Global',
                :order => 3
            }

recipe 'repair', 'Repair Dotnetcli'
