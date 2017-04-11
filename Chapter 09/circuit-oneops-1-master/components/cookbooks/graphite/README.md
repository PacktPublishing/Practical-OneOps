# Graghite Chef Cookbook

This cookbook installs and configures graphite and dependent packages in a clustered environment.

## Overview

Each graphite node runs multiple instances of carbon-relay, carbon-cache, nginx and wsgi. All graphite nodes are identical to each other. The FQDN component acts as a Round-Robin DNS in front of all graphite nodes to balance the read and write.

## Recipes

* `base_install`                     - Install graphite and dependent packages
* `base_install_graphite_web`        - Install nginx and wsgi
* `carbon`                           - Manages graphite carbon related directories and configs
* `nginx_graphite_configs`           - Manages nginx, wsgi related directories and configs

Attributes
----------
