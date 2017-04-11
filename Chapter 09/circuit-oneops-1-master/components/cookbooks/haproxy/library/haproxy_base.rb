# A base/util module for haproxy.
#
# Cookbook Name:: haproxy
# Library:: haproxy_base
#
# Author : OneOps
# Apache License, Version 2.0

module Haproxy

  module Base

    require 'json'
    require 'uri'
    include Chef::Mixin::ShellOut

 
    def delete_lb(conn,lb_name)
      Chef::Log.info("delete lb name: "+lb_name)
      
      # frontend
      response = conn.request(:method => :get, :path => "/frontend/#{lb_name}")      
      puts "response: #{response.inspect}"
      if response.status == 200 
        delete_response = conn.request(:method => :delete, :path => "/frontend/#{lb_name}")
        if response.status == 200
          Chef::Log.info("delete from frontend #{lb_name} done.")
        else
          Chef::Log.error("delete from frontend #{lb_name} failed:")
          puts delete_response.inspect
          exit 1
        end
      else
        Chef::Log.info("already deleted frontend: #{lb_name}")
      end
            
      # backend
      lb_name += "-backend"
      response = conn.request(:method => :get, :path => "/backend/#{lb_name}")      
      puts "response: #{response.inspect}"
      if response.status == 200 
        delete_response = conn.request(:method => :delete, :path => "/backend/#{lb_name}")
        if response.status == 200
          Chef::Log.info("delete from backend #{lb_name} done.")
        else
          Chef::Log.error("delete from backend #{lb_name} failed:")
          puts delete_response.inspect
          exit 1
        end
      else
        Chef::Log.info("already deleted backend: #{lb_name}")
      end
            
    end
 
 
  end

end