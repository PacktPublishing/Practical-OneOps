name                'Java'
description         'Installs/Configures Java'
version             '0.1'
maintainer          'OneOps'
maintainer_email    'support@oneops.com'
license             'Apache License, Version 2.0'


grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'flavor',
          :description => 'Flavor',
          :required => 'required',
          :default => 'openjdk',
          :format => {
              :important => true,
              :help => 'The flavor of Java to use.',
              :category => '1.Source',
              :order => 1,
              :form => {:field => 'select', :options_for_select => [['Oracle Java', 'oracle'], ['OpenJDK', 'openjdk']]}
          }

attribute 'jrejdk',
          :description => 'Package Type',
          :required => 'required',
          :default => 'jdk',
          :format => {
              :important => true,
              :help => 'Java package type to be installed. Server JRE support is only for Java 7 or later',
              :category => '1.Source',
              :order => 2,
              :form => {:field => 'select', :options_for_select => [['JRE', 'jre'], ['JDK', 'jdk'], ['Server JRE', 'server-jre']]}
          }

attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '8',
          :format => {
              :important => true,
              :help => 'The version of Java.',
              :category => '1.Source',
              :order => 3,
              :form => {:field => 'select', :options_for_select => [['6', '6'], ['7', '7'], ['8', '8']]}
          }

attribute 'uversion',
          :description => 'Update',
          :default => '',
          :format => {
              :important => true,
              :help => 'Java update version number. Use empty value for the latest available update version.e.g. "8u51 specify 51"',
              :category => '1.Source',
              :order => 4,
              :pattern => '[0-9\.]+'
          }

attribute 'binpath',
          :description => 'Binary Package',
          :default => '',
          :format => {
              :help => 'Download path of java binary package file. Use it only to install user provided binary package (Use download component to get the installation package).',
              :category => '1.Source',
              :order => 5
          }

attribute 'install_dir',
          :description => 'Installation Directory',
          :default => '/usr/lib/jvm',
          :format => {
              :help => 'Specify the directory path where Java should be installed (required only for non-openjdk flavors).',
              :category => '2.Destination',
              :order => 1
          }

attribute 'sysdefault',
          :description => 'System Default',
          :default => 'true',
          :format => {
              :category => '2.Destination',
              :order => 2,
              :form => {:field => 'checkbox'}
          }

recipe 'repair', 'Repair Java'
