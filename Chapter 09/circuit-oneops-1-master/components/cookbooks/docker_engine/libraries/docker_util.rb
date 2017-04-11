# A utility module for docker.
#
# Cookbook Name:: docker_engine
# Library:: docker_util
#
# Author : OneOps
# Apache License, Version 2.0

module Docker

  module Util

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut

    # Checks whether the platform is supported to install docker engine.
    # Right now only Enterprise Linux 7 (EL7 CentOS/RHEL), which has
    # kernel version 3.10.x or later is supported.
    #
    # @return : true if the platform is supported for docker.
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
      script = "yum list available #{pkg_name}-#{version}"
      Chef::Log.info "Checking the package: #{script}"
      # cmd = shell_out!(script, :live_stream => Chef::Log, :returns => [0, 2])
      cmd = shell_out(script, :live_stream => Chef::Log)
      Chef::Log.info "Exit status: #{cmd.exitstatus}. The #{pkg_name}-#{version} " +
                         "package is #{cmd.exitstatus != 0 ? 'NOT' : '' } available " +
                         'to install from OS repo.'
      cmd.exitstatus == 0
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


    #  Returns the docker engine repository url configured by the user
    #  with fallback to docker cloud mirror service or docker project
    #  default repo.
    #
    def get_docker_repo
      repo = node.docker_engine.repo
      repo = get_mirror_svc('docker') if repo.to_s.strip.empty?
      repo = node.docker_engine.default_repo if repo.to_s.strip.empty?
      repo
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

    # Initialize docker remote client. Make sure to install docker
    # remote API gem (::add_docker_gem) before invoking this method.
    #
    def init_docker_client()
      begin
        require 'docker'
        Chef::Log.info("Connecting to docker daemon on #{Docker.url}")
        if node.docker_engine.tlsverify == 'true'
          Chef::Log.info('Configuring docker TLS options.')
          Docker.url ='tcp://0.0.0.0:2376'
          Docker.options = {
              client_cert: node.docker_engine.tlscert_file,
              client_key: node.docker_engine.tlskey_file,
              ssl_ca_file: node.docker_engine.tlscacert_file,
              scheme: 'https'
          }
        end
        Docker.validate_version!
      rescue Exception => e
        Chef::Log.error(e)
        exit_with_err("Docker client initialization failed, #{e.message}")
      end

    end

  end

end