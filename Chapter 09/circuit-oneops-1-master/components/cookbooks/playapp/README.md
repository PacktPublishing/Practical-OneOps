Description
==========================
This cookbook is designed to be able to describe and deploy playframework  web applications. Application is deployed as a service.

Currently supported:

* SCM deployment / Play dist package deployment
* External application configuration file
* External logger file
* http / https port

Note that this cookbook provides the play-specific bindings for the `application` cookbook; you will find general documentation in that cookbook.

Requirements
------------
Chef 0.10.0 or higher required (for Chef environment use).

#### packages
- `application` - [Opscode application cookbook](https://github.com/opscode-cookbooks/application)
- `play` - [play cookbook](https://github.com/njin-fr/play2)

Attributes
----------

#### play sub-resource LWRP

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>initd_template</tt></td>
    <td>String</td>
    <td>Service script template file</td>
    <td><tt>nil</tt><br/>(use the cookbook one)</td>
  </tr>
  <tr>
    <td><tt>ivy_credentials</tt></td>
    <td>String</td>
    <td>Ivy credentials file</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>application_conf</tt></td>
    <td>String</td>
    <td>Application configuration file</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>log_file</tt></td>
    <td>String</td>
    <td>Log file</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>http_port</tt></td>
    <td>Integer</td>
    <td></td>
    <td><tt>80</tt></td>
  </tr>
  <tr>
    <td><tt>https_port</tt></td>
    <td>Integer</td>
    <td></td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>app_opts</tt></td>
    <td>String</td>
    <td>Additional java options</td>
    <td><tt>Empty string</tt></td>
  </tr>
  <tr>
    <td><tt>app_dir</tt></td>
    <td>String</td>
    <td>Subdirectory within the repo where the play app is located</td>
    <td><tt>./</tt></td>
  </tr>

</table>

Usage
-----
#### A sample application using zip package distribution (Recommended)

	application "my_app" do
		path "/var/www/playapps/#{name}"
		repository "http://my_app.distribution_url.zip"
		revision "1.0.0"
		strategy :dist_remote_file
	
		play do
			ivy_credentials "credentials"
			http_port 80
			application_conf "application.conf"
			log_file "logger.xml"
			app_opts "-Xms6144M -Xmx6144M -Xss1M -XX:MaxPermSize=256M"
		end
	end
	
`credentials`, `application.conf`, `logger.xml` must be in your cookbook files.

#### A sample application using scm provider

	application "my_app" do
		path "/var/www/playapps/#{name}"
		repository "git@repo.url.git"
		revision "master"
		deploy_key "-----BEGIN RSA PRIVATE KEY-----
	ZO83161L458DqWszVwblp4HValWWUm6382OkaGvVGrwGLNTNcoYeWAP0xvpuDLfi
	…U13bIttKqAmYNMK0o+699VWGDf9uBEfwDgBbrMUt+RchxyM3BA==
	-----END RSA PRIVATE KEY-----
	"
	
		play do
			ivy_credentials "credentials"
			http_port 80
			application_conf "application.conf"
			log_file "logger.xml"
			app_opts "-Xms6144M -Xmx6144M -Xss1M -XX:MaxPermSize=256M"
			app_dir  "my-play-app"
		end
	end

Contributing
------------
If your are a ruby guy, please contribute. This cookbook was made by a developer who knows nothing of ruby. You can surely improve the code.

License and Authors
-------------------
Author:: Didier Bathily (<bathily@njin.fr>)

Copyright 2013, njin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
