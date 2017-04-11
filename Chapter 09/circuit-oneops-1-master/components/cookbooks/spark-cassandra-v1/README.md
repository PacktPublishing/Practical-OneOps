Spark Cassandra Connector Cookbook (V1 Build)
==============================================

This cookbook deploys the Spark Cassandra connector into a Spark standalone
cluster.

Usage
-----

To use the component, add it to your assembly.  Configure the Spark version
being installed (or leave as default to auto detect), and deploy.

Using a Custom driver package
-----------------------------

A custom driver package can also be used for Spark versions that are not
listed.  The tarball must contain the drivers that need to be added to the
classpath of the driver and executors in a flat tar with no subdirectories.

Attributes
----------

* `default['spark-cassandra-v1']['spark_version']` - The version of Spark being installed.
* `default['spark-cassandra-v1']['connector_tarball']` - The URL to the tarball containing the connector drivers.
