Kibana Cookbook
=============

Kibana cookbook

Requirements
============

Platform:


How to run
==========


Attributes
==========

source url
kibana version


Description
-----------

This _Chef_ cookbook installs and configures KIBANA
It requires a working ELASTIC SEARCH Cluster.

The cookbook downloads the KIBANA tarball
unpacks and moves it to the directory you have specified in the node configuration (`/app/kibana` by default).

It installs a service which enables you to start, stop, restart and check status of the _Kibana process.

_Kibana 3 does not support Elasticsearch versions greater than 1.7

Usage
-----

source URL is the URL for the file location (excluding the file name).


Tutorial
--------
