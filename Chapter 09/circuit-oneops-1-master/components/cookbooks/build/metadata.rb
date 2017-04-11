name             "Build"
description      "Installs/Configures code builds"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"
depends          "shared"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'scm',
  :description => "Repository Type",
  :required => "required",
  :default => 'git',
  :format => {
    :help => 'Select SCM repository type.',
    :category => '1.Source',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [['Git','git'],['Subversion','svn']] }
  }

attribute 'repository',
  :description => "Repository URL",
  :required => "required",
  :default => 'git://github.com',
  :format => {
    :important => true,
    :help => 'URLs can be in any format that the corresponding SCM repository type supports - http, ssh, git, svn etc.',
    :category => '1.Source',
    :order => 2
  }

attribute 'revision',
  :description => "Revision",
  :required => "required",
  :default => 'HEAD',
  :format => {
    :important => true,
    :help => 'Branch, tag, commit or SCM specific revision id to checkout',
    :category => '1.Source',
    :order => 3
  }

attribute 'depth',
  :description => "Depth",
  :default => '',
  :format => {
    :help => '(Git only) Number of past revisions to include in Git shallow clone',
    :category => '1.Source',
    :order => 4
  }

attribute 'submodules',
  :description => "Submodules",
  :default => 'false',
  :format => {
    :help => '(Git only) Performs a submodule init and submodule update',
    :category => '1.Source',
    :order => 5,
    :form => { 'field' => 'checkbox' }
  }

attribute 'username',
  :description => "Username",
  :format => {
    :help => 'Username to authenticate against the SCM source repository',
    :category => '1.Source',
    :order => 10
  }

attribute 'password',
  :description => "Password",
  :encrypted => true,
  :format => {
    :help => 'Password to authenticate against the SCM source repository',
    :category => '1.Source',
    :order => 11
  }

# pattern for public ssh keys ^ssh\-[a-z]{3}\s\S+(\s\S+)?$
attribute 'key',
  :description => "Private SSH key for restricted repository access",
  :data_type => "text",
  :format => {
    :help => 'Use private SSH key as an alternative to the username/password authentication',
    :category => '1.Source',
    :order => 12,
    :pattern => '.*BEGIN.*PRIVATE.*KEY.*'
  }


attribute 'install_dir',
  :description => "Install Directory",
  :format => {
    :help => 'Directory path where the source code will be downloaded and versions will be kept (Note: the latest code will be in a sub-directory current)',
    :category => '2.Destination',
    :order => 1,
    :pattern => '^((?:[\/\$][\${}a-zA-Z0-9]+(?:_[\${}a-zA-Z0-9]+)*(?:-[\${}a-zA-Z0-9]+)*)+)$'
  }

attribute 'as_user',
  :description => "Deploy as user",
  :format => {
    :help => 'System user to run the deploy as (root if not specified)',
    :category => '2.Destination',
    :order => 2
  }

attribute 'as_group',
  :description => "Deploy as group",
  :format => {
    :help => 'System group to run the deploy as (root if not specified)',
    :category => '2.Destination',
    :order => 3
  }

attribute 'environment',
  :description => "Environment Variables",
  :data_type => 'hash',
  :default => '{}',
  :format => {
    :help => 'Specify variables that will be available in the environment during deployment',
    :category => '2.Destination',
    :order => 4
  }

attribute 'ci',
  :description => "Continuous Integration",
  :default => 'false',
  :format => {
    :help => 'Sets up a 5-minute cron job to keep the code up-to-date at the specified revision',
    :category => '2.Destination',
    :order => 5,
    :form => { 'field' => 'checkbox' }
  }

attribute 'before_migrate',
  :description => "Callback block before_migrate",
  :data_type => "text",
  :format => {
    :help => 'Content must be Chef ruby block.',
    :category => '3.Migration',
    :order => 1
  }

attribute 'migration_command',
  :description => "Build / Migration Commands",
  :data_type => "text",
  :format => {
    :help => 'These commands are executed in a directory which is not active yet and activation (symlink) of the updated code depends on the successful execution of these commands',
    :category => '3.Migration',
    :order => 2
  }

attribute 'persist',
  :description => "Persistent Directories",
  :data_type => 'array',
  :default => '[]',
  :format => {
    :help => 'List of directories to be persisted across code updates (for example logs, tmp etc)',
    :category => '3.Migration',
    :order => 3
  }

attribute 'before_restart',
  :description => "Callback block before_restart",
  :data_type => "text",
  :format => {
    :help => 'Content must be Chef ruby block and execution happens after new code is activated',
    :category => '4.Restart',
    :order => 1
  }

attribute 'restart_command',
  :description => "Restart Command",
  :format => {
    :help => 'Optional command to execute after new code is activated',
    :category => '4.Restart',
    :order => 2
  }

recipe "redeploy", "Re-Deploy"
recipe "repair", "Repair"
