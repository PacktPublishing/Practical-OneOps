Description
===========

Installs and configures java (JDK/JRE/Server JRE)

Requirements
============

Platform:

* OpenStack
* Rackspace
* Azure

Dependencies:


Attributes
==========

* `flavor`  - Java vendor to be installed, default `Oracle Java`.
* `jrejdk`  - Java binary package type, default `Server JRE`.
* `version` - Java version to be installed, default `1.8`.
* `update`  - Java update version, default `varies on version`
* `binpath` - Java package download path, default `/usr/src/jdk-linux-x64.bin`.
* `install_dir` - Java installation directory, default `/usr/lib/jvm`.
* `sysdefault`  - Make java system default, default `true`.


USAGE
=====



