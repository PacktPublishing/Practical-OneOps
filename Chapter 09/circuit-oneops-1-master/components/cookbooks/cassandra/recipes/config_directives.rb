#
# Cookbook Name:: cassandra
# Recipe:: config_directives
#
# Copyright 2015, @WalmartLabs.

require 'json'

ruby_block 'update_config_directives' do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    cfg = JSON.parse(node.workorder.rfcCi.ciAttributes.config_directives)

    if node[:workorder][:rfcCi][:ciAttributes].has_key?("cluster")
      cfg["cluster_name"] = node[:workorder][:rfcCi][:ciAttributes][:cluster]
    end

    if node[:workorder][:rfcCi][:ciAttributes].has_key?("num_tokens")
      cfg["num_tokens"] = node[:workorder][:rfcCi][:ciAttributes][:num_tokens]
    end

    if node[:workorder][:rfcCi][:ciAttributes].has_key?("partitioner")
      cfg["partitioner"] = node[:workorder][:rfcCi][:ciAttributes][:partitioner]
    end

    if node[:workorder][:rfcCi][:ciAttributes].has_key?("auth_enabled")
      cfg["authenticator"] = node[:auth_enabled] == 'true' ? 'PasswordAuthenticator' : 'AllowAllAuthenticator'
      cfg["authorizer"] = node[:auth_enabled] == 'true' ? 'CassandraAuthorizer' : 'AllowAllAuthorizer'
    end

    puts "seeds: #{node[:initial_seeds].join(",")}"

    cfg["seed_provider"]=[{"class_name"=>"org.apache.cassandra.locator.SimpleSeedProvider", "parameters"=>[{"seeds"=>node[:initial_seeds].join(",")}]}]
    puts "full cfg: #{cfg.to_yaml}"

    cfg["listen_address"] = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
    cfg["broadcast_rpc_address"] = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
    cfg["rpc_address"] = "0.0.0.0"

    if node[:workorder][:rfcCi][:ciAttributes].has_key?("endpoint_snitch")
      cfg["endpoint_snitch"] = node.workorder.rfcCi[:ciAttributes][:endpoint_snitch]
    end

    yaml_file = '/opt/cassandra/conf/cassandra.yaml'
    Chef::Application.fatal!("Can't find the YAML config file - #{yaml_file} ") if !File.exists? yaml_file
    merge_conf_directives(yaml_file, cfg)
  end
  only_if { conf_directive_supported? }
end
