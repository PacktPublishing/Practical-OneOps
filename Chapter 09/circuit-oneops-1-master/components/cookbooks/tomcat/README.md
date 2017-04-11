Description
===========

Installs and configures the Tomcat, Java servlet engine and webserver.

Requirements
============

Platform: 

* Debian, Ubuntu (OpenJDK, Sun)
* CentOS, Red Hat, Fedora (OpenJDK)

Dependencies:

* java
* jpackage

Attributes
==========

* `port` - The network port used by Tomcat's HTTP connector, default `8080`.
* `server_port` - The server port used by Tomcat, default `8005`.
* `ssl_port` - The network port used by Tomcat's SSL HTTP connector, default `8443`.
* `ajp_port` - The network port used by Tomcat's AJP connector, default `8009`.
* `java_options` - Extra options to pass to the JVM, default `-Xmx128M -Djava.awt.headless=true`.
* `use_security_manager` - Run Tomcat under the Java Security Manager, default `false`.

TODO
====

* SSL support
