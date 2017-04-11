Telegraf Cookbook
=================
Telegraf is an agent written in Go for collecting metrics from the system it's running on, or from other services, and writing them into InfluxDB or other outputs.

Design goals are to have a minimal memory footprint with a plugin system so that developers in the community can easily add support for collecting metrics from well known services (like Hadoop, Postgres, or Redis) and third party APIs (like Mailchimp, AWS CloudWatch, or Google Analytics).

Requirements
------------

Attributes
----------
Version: version number of the component to install
Config: the telegraf configuration file

Usage
-----
Authors: kho@walmartlabs.com
