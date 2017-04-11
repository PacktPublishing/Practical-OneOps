# Cookbook Name:: Java
# Library:: java_util
#
# Author : Suresh G
# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Java

  module Util

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut

    # Returns the current java version installed on the system
    #
    # @return : java version (Eg: 1.8.0_25)
    #
    def java_version
      ver_str = `java -version 2>&1 | grep "java version"`
      Chef::Log.info "Java version string: #{ver_str}"
      # Strip the 'java version ".."' from the string
      (!ver_str.nil? && !ver_str.empty?) ? ver_str.gsub(/[java version *,",\n]/, '') : `Chef::Log.error "Java version is empty. Cannot Proceed further..."`
    end

    # Checks whether the system has given version of java installed
    #
    # @param  : java major version as reported in 'java -version'. Eg: 8, 7 etc
    # @return : true if the specific version found.
    #
    def has_java_version?(ver)
      java_version.start_with? "1.#{ver}"
    end

    # Checks whether the given file is an executable.
    #
    # @param  : file to be checked.
    # @return : true if the file is a linux ELF 64-bit LSB executable.
    #
    def is_executable?(file)
      mime = `file -b --mime-type #{file}`
      mime.start_with?('application/x-executable')
    end

    # Get a list of tools available in the installed java package.
    #
    # @param java_home : java home directory
    # @param scan      : Automatically scans the java_home/bin directory for
    #                    executables instead of using a pre-defined list of tools.
    #                    False by default.
    #
    # @return : List of JDK tools except java
    #
    def get_java_tools(java_home, scan = false)
      bin_files = Dir["#{java_home}/bin/*"].entries

      if scan
        # Latest jdk tools except java.
        Chef::Log.info "Scanning all JDK executables in #{java_home}"
        return bin_files.select { |file| is_executable?(file) }.map { |path| File.basename path } - ['java']
      end

      Chef::Log.info 'Using a pre defined list of java tools.'
      @allowed_tools = %w( appletviewer extcheck idlj jar jarsigner javac javadoc javafxpackager javah javap javapackager javaws jcmd jconsole jcontrol jdb jdeps jhat jinfo jjs jmap jmc jps jrunscript jsadebugd jstack jstat jstatd jvisualvm keytool native2ascii orbd pack200 policytool rmic rmid rmiregistry schemagen serialver servertool tnameserv unpack200 wsgen wsimport xjc)
      # Filter based on whats available on JDK bin directory.
      bin_files.map { |file| File.basename file }.select { |name| @allowed_tools.include? name }
    end

    # Get OpenJDK os package name used by package managers based
    # on the OS platform family, java version and package type.
    #
    # @param   : platform - os platform family (Eg: debian, rhel)
    # @param   : version - java major version (Eg: 8, 7 etc)
    # @param   : type - java package type (Eg: JDK/JRE)
    #
    # @return  : java package name
    #            Eg: java-1.7.0-openjdk-devel (RHEL JDK)
    #                java-1.7.0-openjdk (RHEL JRE)
    #                openjdk-8-jdk (Debian JDK)
    #                openjdk-8-jre (Debian JRE)
    #
    def get_java_ospkg_name (platform, version, type)
      pfx = "#{platform.downcase == 'rhel' ? "java-1.#{version}.0-" :''}"
      case platform.downcase
        when 'rhel'
          sfx = (type.downcase == 'jre' ? '' :'-devel')
        else
          sfx = "-#{version}-".concat(type.downcase == 'jre' ? 'jre' :'jdk')
      end
      "#{pfx}openjdk#{sfx}"
    end

    # Get the Oracle java package update version from node configuration
    # (node.java.uversion). If it's empty/not exists returns default value
    # for the JDK version. Default values are defined in the attribute file
    # (Eg: node[:java]['8u']['version'])
    #
    # @returns : Oracle java update version
    #
    def get_update_ver
      uversion = node.java.uversion
      (uversion.nil? || uversion.empty?) ? node[:java]["#{node.java.version}u"]['version'] : uversion
    end


    # Get the Oracle java package file extension. OneOps uses tar.gz packages for
    # JDK 7 or later and .bin file for JDK6. Default values are defined in the
    # attribute file.
    #
    # @retuns : Oracle java package extension
    #
    def get_pkg_extn
      node.java.version == '6' ? 'bin' : node[:java]['package']['extn']
    end


    # Validates the user given java package file.
    #
    # @return : 2-Tuple(update version, extract dir)
    #
    def validate_pkg_file(filename)
      Chef::Log.info("Validating java package file : #{filename}")
      java_pkg = /
                  ^                         # Starting at the front of the string
                  (?i)(jre|jdk|server-jre)  # Capture any of the case insensitive package type; call the result "Pkg"
                  -                         # Eat the delimiter '-'
                  (\d+)                     # Capture major version number; call it "Version"
                  u?(\d*)                   # Capture optional update version excluding 'u'; call the result "Update"
                  -                         # Eat the delimiter '-'
                  (\S+)-                    # Capture all the non-whitespace till '-'; call it "OS"
                  ((?i)x\d+)                # Capture all integers; call it "Arch"
                  \.                        # Eat the extension delimiter '.'
                  (\S+)                     # Capture all the non-whitespace; call it "Extn"
                  $                         # End of the line now
              /x

      parts = filename.match(java_pkg)
      exit_with_err "#{filename} is not of a valid java package file name format." if parts.nil?
      pkg = parts[1]
      version = parts[2]
      uversion = parts[3]
      # os = parts[4]
      # arch = parts[5]
      # extn = parts[6]

      exit_with_err("Installation file does not match the selected java package: #{node[:java][:jrejdk]}") if pkg != node[:java][:jrejdk]
      exit_with_err("Installation file does not match the selected java version: #{node[:java][:version]}") if version != node[:java][:version]

      extract_dir = get_extract_dir(pkg, version, uversion)
      return uversion, extract_dir
    end

    # Returns the expanded directory name created after installation
    # of the given java package file name. The Oracle jdk format is
    # <jre/jdk>1.<version>.0[_<update>]
    # Eg:  For Java-8 Server JRE - jdk1.8.0_25
    #
    # @param pkg : Java package type
    # @param version : Java version
    # @param update : Java update version
    #
    # @return : expanded directory name.
    #
    def get_extract_dir(pkg, version, update)
      dir = "#{pkg == 'jre' ? 'jre' : 'jdk'}1.#{version}.0#{update.empty? ? '' : '_'+update}"
      Chef::Log.info("Java package expanded dir: #{dir}")
      dir
    end

    # Returns mirror url for the given service. Will first look into
    # the component attributes for mirror url and then in the cloud
    # mirror service if it's empty.
    #
    # @param name mirror service name
    # @return service url
    #
    def get_mirror_svc(name)
      cloud = node.workorder.cloud.ciName
      cookbook = node.app_name.downcase

      svc_url = node[cookbook][:mirror]
      Chef::Log.info("Component mirror url for #{cookbook} is #{svc_url.nil? ? 'not configured.' : svc_url}")
      return svc_url if (!svc_url.nil? && !svc_url.empty?)

      Chef::Log.info("Getting #{cloud} cloud mirror service for #{cookbook}")
      mirror_svc = node[:workorder][:services][:mirror]
      mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) unless mirror_svc.nil?

      # Search for service.
      (!mirror.nil? && mirror.has_key?(name)) ? mirror[name] : ''
    end

    # Returns java pkg download location by following the JDK naming convention.
    # Refer http://goo.gl/W4jChU for more details. The base url is formed based
    # on the JDK mirror service (or any http mirror location) configured in the
    # cloud. Java version, update & pkg details are read from chef node object.
    #
    # @returns : 3-Tuple (baseurl, filename, extract dir)
    #            Base URL - Package base url
    #            File name - Package file name to download
    #            Extract dir - Package extract dir name
    #
    def get_java_pkg_location
      cookbook = node.app_name.downcase
      base_url = get_mirror_svc('jdk')

      version = node.java.version
      update = get_update_ver
      pkg = node.java.jrejdk
      extn = get_pkg_extn
      artifact = "#{version}u#{update}-linux"

      # Replace any $version/$flavor/$jrejdk placeholder variables present in the URL
      # e.x: http://<mirror>/some/path/$flavor/$jrejdk/$version/$jrejdk-$version-$arch.$extn
      base_url = base_url.gsub('$version', artifact)
                     .gsub('$jrejdk', pkg)
                     .gsub('$flavor', node[cookbook][:flavor])
                     .gsub('$arch', node.java.arch)
                     .gsub('$extn', extn)
      exit_with_err("Invalid package base URL: #{base_url}") unless url_valid?(base_url)

      if base_url.end_with? (extn)
        # Got full mirror url with file name.
        file_name = File.basename(URI.parse(base_url).path)
        base_url = File.dirname(base_url)
      else
        # Use JDK file name convention.
        file_name = "#{pkg}-#{artifact}-#{node.java.arch}.#{extn}"
      end

      Chef::Log.info("Package url: #{base_url}/#{file_name}")
      extract_dir = get_extract_dir(pkg, version, update)
      return base_url, file_name, extract_dir

    end

    # Checks if the given string is a valid http/https URL
    #
    # @param - URL string to check
    def url_valid?(url)
      url = URI.parse(url) rescue false
      url.kind_of?(URI::HTTP) || url.kind_of?(URI::HTTPS)
    end

    # Exit the chef application process with the given error message
    #
    # @param : msg -  Error message
    #
    def exit_with_err(msg)
      Chef::Log.error(msg)
      puts "***FAULT:FATAL=#{msg}"
      Chef::Application.fatal!(msg)
    end

  end

end