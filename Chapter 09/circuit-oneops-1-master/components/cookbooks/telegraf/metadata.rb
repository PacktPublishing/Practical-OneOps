name             "Telegraf"
description      "telegraf"
version          "0.1"
maintainer       "OneOps"
maintainer_email "kho@walmartlabs.com"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


# installation attributes
attribute 'version',
  :description          => 'Telegraf version',
  :required => "required",
  :default               => '1.0.0',
  :format => {
    :important => true,
    :category => 'Global',
    :help => 'Version of Telegraf',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['v0.13.2', '0.13.2'],['v1.0.0', '1.0.0']]}
  }


attribute 'enable_agent',
  :description => "Enable agent",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'This will control whether the telegraf agent should be running.',
      :order => 2,
      :form => {'field' => 'checkbox'}
  }

attribute 'enable_test',
  :description => "Enable Test",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'If enabled, then during add/update, [telegraf -test] must be run to validate the configuration..',
      :order => 3,
      :form => {'field' => 'checkbox'}
  }

attribute 'run_as_root',
  :description => "Run As Root",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'Run Telegraf process as Root',
      :order => 4,
      :form => {'field' => 'checkbox'}
  }

attribute 'configdir',
  :description => "Config File Directory",
  :required => 'required',
  :default => '/etc/telegraf/',
  :format => {
    :help => 'Config file directory',
    :category => 'Global',
    :order => 5
  }



attribute 'configure',
  :description => "Configuration file Contents",
  :data_type => "text",
  :format => {
    :help => 'Resources to be executed to configure the telegraf package.',
    :category => 'Global',
    :order => 6
  }


recipe "start", "Start Telegraf"
recipe "stop", "Stop Telegraf"
recipe "restart", "Retart Telegraf"
recipe "status", "Telegraf Status"


