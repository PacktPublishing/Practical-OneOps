name             "Rabbitmq_server"
description      "Installs/Configures ActiveMQ"
version          "0.1"
maintainer       "OneOps"
license          "Copyright OneOps, All rights reserved."

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => "Version",
  :required => "required",
  :default => "3.6.6",
  :format => {
    :help => 'Version of RabbitMQ',
    :category => '1.Global',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['3.6.6','3.6.6']] }
  }

attribute 'erlangcookie',
  :description => "Erlang Cookie",
  :encrypted => true,
  :default => "DEFAULTCOOKIE",
  :format => {
    :help => 'Unique Erlang cookie used for inter-node communication',
    :category => '1.Global',
    :order => 2
  }

attribute 'guest_user',
  :description => "Guest User",
  :required => "required",
  :default => "guest123",
  :format => {
    :help => 'Guest User',
    :category => '2.User',
    :order => 1
  }

attribute 'guest_password',
  :description => "Guest Password",
  :required => "required",
  :encrypted => true,
  :default => "guest123",
  :format => {
    :help => 'Guest Password',
    :category => '2.User',
    :order => 2
  }

attribute 'admin_user',
  :description => "Admin User",
  :required => "required",
  :default => "nova",
  :format => {
    :help => 'Nova User',
    :category => '2.User',
    :order => 3
  }

attribute 'admin_password',
  :description => "Admin Password",
  :required => "required",
  :encrypted => true,
  :default => "nova",
  :format => {
    :help => 'Nova Password',
    :category => '2.User',
    :order => 4
  }

attribute 'environment_variables',
  :description => "Environment Variables Configuration file",
  :data_type   => "hash",
  :default     => '{"RABBITMQ_NODE_PORT":"5672", "RABBITMQ_MNESIA_BASE":"/data/rabbitmq/mnesia", "RABBITMQ_LOG_BASE":"/log/rabbitmq"}',
  :format      => {
  :help     => 'key-value pair for environment variables',
  :category => '3.Config',
  :order    => 1
  }

attribute 'config_variables',
  :description => "Configuration file",
  :data_type   => "hash",
  :default     => "{}",
  :format      => {
  :help     => 'key-value pair for configuration variables',
  :category => '3.Config',
  :order    => 2
  }

recipe "status", "Rabbitmq Status"
recipe "start", "Start Rabbitmq"
recipe "stop", "Stop Rabbitmq"
recipe "restart", "Restart Rabbitmq"
recipe "repair", "Repair Rabbitmq"
