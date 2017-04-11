name 'Orientdb'
maintainer 'OneOps'
maintainer_email 'support@oneops.com'
license 'Apache'
description 'Installs/Configures orientdb'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1'
depends 'apt', '= 3.0.0'
depends 'tar', '= 1.1.0'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest','bom']


attribute 'version',
  :description => 'Version',
  :required => 'required',
  :default => '2.2.16',
  :format => {
    :help => 'Version of OrientDB',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['2.2.16','2.2.16'],['2.2.15','2.2.15']] }
  }

recipe "status", "orientdb Status"
recipe "start", "orientdb Start"
recipe "stop", "orientdb Stop"
recipe "restart", "orientdb Restart"
recipe "repair", "orientdb Repair"
