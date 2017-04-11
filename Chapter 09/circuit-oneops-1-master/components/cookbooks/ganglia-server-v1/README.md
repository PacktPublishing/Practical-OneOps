Ganglia Server Cookbook (v1 Build)
==================================

This cookbook deploys a Ganglia Server along with the metastore daemon process.

Usage
-----

To use the pack, add it to your assembly, then deploy.

Attributes
----------

* `default['ganglia-server-v1']['grid_name']` - The grid name to use.
* `default['ganglia-server-v1']['data_source_map']` - A list of additional data sources to define.
* `default['ganglia-server-v1']['gweb_port']` - The port for the web server to listen on.
* `default['ganglia-server-v1']['polling_interval']` - Polling interval in seconds for getting data from data sources.
