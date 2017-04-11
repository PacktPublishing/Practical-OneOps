squid Cookbook
==============
Configures squid as a caching proxy.


Recipes
-------
### default
The default recipe installs squid and sets up simple proxy caching. As of now, the options you may change are the port (`node['squid']['port']`) and the network. Caching proxy is available on the subnet from `node.ipaddress` (ie. "192.168.1.0/24") but may be overridden with `node['squid']['network']`. The size of objects allowed to be stored has been bumped up to allow for caching of installation files.

