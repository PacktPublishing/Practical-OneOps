
Description
===========

Installs and configures .NET CLI

Requirements
============

Platform:
* centos-7
* OpenStack
* Rackspace
* Azure

Dependencies:


Attributes
==========

* `flavor`  - Dotnet vendor to be installed, default `Dotnet CLI centos-7`.
* `jrejdk`  - Dotnet binary package type, default `Dotnet CLI centos-7`.
* `version` - Dotnet version to be installed, default `1`.
* `update`  - Dotnet update version, default `varies on version`
* `binpath` - Dotnet package download path, default `/usr/src/dotnet-dev-centos-x64.latest.tar.gz`.
* `install_dir` - Dotnet installation directory, default `/usr/share/dotnet`.
* `sysdefault`  - Make Dotnet system default, default `true`.


USAGE
=====
