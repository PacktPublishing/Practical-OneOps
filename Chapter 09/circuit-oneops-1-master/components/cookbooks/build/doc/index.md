A build component is used to fetch some source code and build it.

The repository attribute can be a URL in any format that the corresponding SCM repository type supports - http, ssh, git, svn etc.

The username and password attributes or the (ssh) key attribute can be used to authenticate. 

The before_migrate, migration_command, before_restart, and restart_command attributes are used to build, install/migrate, and restart.  Use chef dsl language in these attributes.
