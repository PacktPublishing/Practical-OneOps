{::options template="document" /}

Spark Pack (V1 Build)
=====================

This pack is used to deploy a Spark standalone cluster.

Deployment Layout
-----------------
In general, the cluster is set up to include a single Spark master for each cloud.
The number of workers is controlled by the redundancy applied to the platform.

How to Use
-------------
Once the pack is created, there are a number of attributes that need to be configured.

Design View {#design}
-----------
In the design view there are a number of components such as **compute** that are standard
components in pack development.  A unique aspect of the Spark pack is that there are a
duplicate set of components for the Spark master.  These are generally named
componentname**-master**.

The configuration of Spark itself is all handled through the **spark** component.

Transition {#transition}
----------
In the transition view, all of the components that are in the design view appear with
one addition.  A component named *spark-worker* is present in the transition view to
represent the Spark deployment on Spark workers.  Please be aware that the settings in
this component are not used...all Spark settings are read from the #spark# component.

Operations {#operations}
----------
In the operations view, the status of all deployed components can be viewed.

