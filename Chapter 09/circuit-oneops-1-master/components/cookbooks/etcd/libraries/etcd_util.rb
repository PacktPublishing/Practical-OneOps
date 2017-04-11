# A utility module for etcd.
#
# Cookbook Name:: etcd
# Library:: etcd_util
#
# Author : OneOps
# Apache License, Version 2.0

module Etcd

  module Util

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut

    # Checks whether the platform is supported to install etcd.
    # Supports only EL7 (CentOS/RHEL) with kernel version 3.10.x
    # or later.
    #
    # @return : true if the platform is supported for etcd.
    #
    def is_platform_supported?
      plf = node.platform_family.downcase
      ver = node.platform_version.to_i
      Chef::Log.info "Checking platform support. Platform: #{plf}, version: #{ver}"
      plf == 'rhel' && ver >= 7
    end

    # Checks if the given package is available from the OS repo to install.
    #
    # @param pkg_name linux package name
    # @param version package version
    #
    # @return true if the  package is available.
    #
    def is_pkg_avail?(pkg_name, version)

      return false unless is_platform_supported?

      script = "yum list available #{pkg_name}-#{version}"
      Chef::Log.info "Checking the package: #{script}"
      cmd = shell_out(script, :live_stream => Chef::Log)
      Chef::Log.info "Exit status: #{cmd.exitstatus}. The #{pkg_name}-#{version} " +
                         "package is #{cmd.exitstatus != 0 ? 'NOT' : '' } available " +
                         'to install from OS repo.'
      cmd.exitstatus == 0
    end
    
    def is_installed?(pkg_name, version)

      installed_version = shell_out("#{pkg_name} --version | head -1 | awk '{print $3}'").stdout.chomp
      Chef::Log.info "installed_version: #{installed_version}"
      
      version == installed_version
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

      # Search for service. If it can't find, use the default release url.
      (!mirror.nil? && mirror.has_key?(name)) ? mirror[name] : node.etcd.release_url
    end

    # Returns pkg download location for the given cookbook artifact.
    # The base url is formed based on the cookbook mirror service.
    #
    # @param cookbook - cookbook name.
    #
    # @returns : 2-Tuple (baseurl, filename)
    #            Base URL - Package base url
    #            File name - Package file name to download
    #
    def get_pkg_location(cookbook)

      version = node.etcd.version
      base_url = get_mirror_svc('etcd')
      Chef::Log.info("Etcd base_url: #{base_url}")

      # Replace any $version/$arch/$extn placeholder variables present in the URL
      # e.x: https://github.com/coreos/etcd/releases/download/v$version/etcd-v$version-$arch.$extn
      base_url = base_url.gsub('$version', version)
                     .gsub('$arch', node.etcd.arch)
                     .gsub('$extn', node.etcd.extn)
      exit_with_err("Invalid package base URL: #{base_url}") unless url_valid?(base_url)

      file_name = File.basename(URI.parse(base_url).path)
      Chef::Log.info("Package url: #{base_url}, filename: #{file_name}")
      return File.dirname(base_url), file_name

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
    
    def get_etcd_members_http(host, port)
      
      uri = URI.parse("http://#{host}:#{port}/v2/members")
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.path)
      res = http.request(req)
      if res.code != '200'
        exit_with_err("Failure getting etcd members. response code: #{res.code}, response body #{res.body}, response message #{res.message}")
      end
      
      return res.body
    end
    
    # Test if Etcd is running at some host by GET the list of members via http
    #
    # @param - host
    # @param - port
    
    require 'socket'
    require 'timeout'

    def is_port_open?(ip, port)
      begin
        Timeout::timeout(1) do
          begin
            s = TCPSocket.new(ip, port)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            return false
          end
        end
      rescue Timeout::Error
      end
            
      return false
    end
    
    def get_full_hostname(ip)
      full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
      while true
        if full_hostname =~ /NXDOMAIN/
          Chef::Log.info("Unable to resolve hostname from #{ip} by PTR, sleep and retry")
          sleep(5)
          full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
        else
          break;
        end
      end
      return full_hostname
    end
    
    def get_fqdn(ip, platform_level)
      full_hostname = get_full_hostname(ip)
      # full_hostname is the cloud-level and instance-level FQDN
      # but we need to use cloud-level FQDN to connect to the Etcd running in (primary or secondary) clouds
      # the temp solution is to:
      # (1) drop the short hostname
      # (2) add the platform name in front
      arr = full_hostname.split(".")[1..-1]
      platform_name = node.workorder.box.ciName
      
      # if platfor_level = true, drop cloud info (e.g. dfwiaas4) from cloud-level domain
      if platform_level == true
        arr.delete_at(3)
      end
      
      cloud_fqdn = [platform_name, arr.join(".")].join(".")
      Chef::Log.info("fqdn: #{cloud_fqdn}")
      return cloud_fqdn
    end
    
    def depend_on_hostname_ptr?
      # if etcd depends on hostname/fqdn componenet with PTR enabled
      depend_on_fqdn_ptr = false
      node.workorder.payLoad[:DependsOn].each do |dep|
        if dep["ciClassName"] =~ /Fqdn/
          if !dep["ciBaseAttributes"].nil? && !dep["ciBaseAttributes"].empty?
            hash = dep["ciBaseAttributes"]
          else
            hash = dep["ciAttributes"]
          end
                
          if hash["ptr_enabled"] == "true"
            depend_on_fqdn_ptr = true
            Chef::Log.info("depend_on_fqdn_ptr")
            break
          end
        end
      end
    return depend_on_fqdn_ptr
    end
  end

end
