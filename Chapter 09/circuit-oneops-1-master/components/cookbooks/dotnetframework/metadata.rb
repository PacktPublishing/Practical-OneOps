name             'Dotnetframework'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook install .net frameworks'
version          '0.1.0'

supports 'windows'

grouping 'default',
  :access   => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'chocolatey_package_source',
  :description => 'Package url',
  :default     => 'https://chocolatey.org/api/v2/',
  :required    => "required",
  :format      => {
    :help      => 'Chocolatey package url for the .net framework chocolatey packages',
    :category  => '1.Chocolatey Package Source',
    :order     => 1
  }

attribute 'dotnet_version_package_name',
  :description => ".Net Framework version",
  :data_type   => "hash",
  :default     => '{ ".Net 4.6":"dotnet4.6" }',
  :format      => {
    :help      => 'Add .net framework version. Format: .Net <version> = <chocolatey package name>',
    :category  => '2.Framework version',
    :order     => 1
  }
