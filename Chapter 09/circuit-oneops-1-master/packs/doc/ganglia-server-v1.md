{::options template="document" /}

Ganglia Pack (RC7 Build)
========================
This pack is used to deploy a Ganglia monitoring server.

Deployment Layout
-----------------
In general, the pack deploys into a single redundancy environment.
If a redundant environment is used, then the end result is multiple
separate servers.

Ganglia is installed by attempting to install the packages named **ganglia-gmond**, **ganglia-gmetad**, and **ganglia-web**

How to Use
-------------
The pack by default creates a grid named "Ganglia Grid" on the server with the
server listening on port 80.  One or more data sources can be added by specifying two things:

1. A port value
2. A cluster name

This will create a gmond instance on the server listening for Ganglia metrics.  Metrics
reported to this instance will be shown under the specific cluster name.

By default, ports 8800-8899 are opened in the pack for these gmond instances, although
with the proper configuration, this port range can be changed.

Design View {#design}
-----------
In the design view there are a number of components such as **compute** that are standard
components in pack development.  The entire configuration of the Ganglia server is
contained within the **ganglia-server** component.

Transition {#transition}
----------
In the transition view, all of the components that are in the design view appear.

Operations {#operations}
----------
In the operations view, the status of all deployed components can be viewed.

**Monitors** - The Ganglia pack includes the following monitors:

* **CheckGMeta** - This monitor reports whether the gmetad instance on the Ganglia server is still running and accessible.

Other Notes
-----------
The Ganglia deployment guide can be found at:

<https://confluence.walmart.com/display/DTBFDP/Ganglia+Deployment+Guide>
