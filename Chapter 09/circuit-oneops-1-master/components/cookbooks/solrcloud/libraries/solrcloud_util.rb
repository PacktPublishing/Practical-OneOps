#
# Cookbook Name :: solrcloud
# Library :: solrcloud_util
#
# A utility module to deal with helper methods.
#

module SolrCloud

  module Util

    require 'json'
    require 'net/http'

    include Chef::Mixin::ShellOut

    def downloadconfig(solrversion,zkHost,configname)
      begin
        if "#{solrversion}".start_with? "4."
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}")
          bash 'download_config' do
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}
            EOH
            not_if { "#{configname}".empty? }
            ignore_failure true
          end
        end
        if ("#{solrversion}".start_with? "5.") || ("#{solrversion}".start_with? "6.")
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}")
          bash 'download_config' do
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd downconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/#{configname} -confname #{configname}
            EOH
            not_if { "#{configname}".empty? }
            ignore_failure true
          end
        end
      rescue
        Chef::Log.error("Failed to download config. Config '#{configname}' may not exists.")
      else
        Chef::Log.info("Successfully downloaded config '#{configname}'")
      ensure
        puts "End of download_config execution."
      end
    end

    def uploadprodconfig(solrversion,zkHost,configname)
      solrmajorversion = "#{solrversion}"[0,1]
      Chef::Log.info("#{solrmajorversion}")
      begin
        if "#{solrversion}".start_with? "4."
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/prod -confname #{configname}")
          bash 'upload_prod_config' do          
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/prod -confname #{configname}
            EOH
            not_if { ::File.exists?(node['user']['dir']+"/solr-config/#{configname}") }
          end
        end
        if ("#{solrversion}".start_with? "5.") || ("#{solrversion}".start_with? "6.")
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib#{solrmajorversion}/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config#{solrmajorversion}/prod -confname #{configname}")
          bash 'upload_prod_config' do          
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib#{solrmajorversion}/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config#{solrmajorversion}/prod -confname #{configname}
            EOH
            not_if { ::File.exists?(node['user']['dir']+"/solr-config#{solrmajorversion}/#{configname}") }
          end
        end
      rescue
        raise "Failed to upload prod config. Config '#{configname}' does not exists."
      else
        Chef::Log.info("Successfully uploaded config '#{configname}'")
      ensure
        puts "End of upload_prod_config execution."
      end
    end

    def uploaddefaultconfig(solrversion,zkHost,configname)
      solrmajorversion = "#{solrversion}"[0,1]
      Chef::Log.info("#{solrmajorversion}")
      begin
        if ("#{solrversion}".start_with? "4.")
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/default -confname #{configname}")
          bash 'upload_default_config' do            
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['user']['dir']}/solr-config/default -confname #{configname}
            EOH
            not_if { ::File.exists?(node['user']['dir']+"/solr-config/#{configname}") }
          end
        end
        if ("#{solrversion}".start_with? "5.") || ("#{solrversion}".start_with? "6.")
          Chef::Log.info("java -classpath .:#{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['installation_dir_path']}/solr#{solrmajorversion}/server/solr/configsets/data_driven_schema_configs/conf -confname #{configname}")
          bash 'upload_default_config' do
            code <<-EOH
              java -classpath .:#{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}/* org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost #{zkHost} -confdir #{node['installation_dir_path']}/solr#{solrmajorversion}/server/solr/configsets/data_driven_schema_configs/conf -confname #{configname}
            EOH
            not_if { ::File.exists?(node['user']['dir']+"/solr-config"+node['solrmajorversion']+"/#{configname}") }
          end
        end
      rescue
        Chef::Log.error("Failed to upload config. Config '#{configname}' does not exists.")
      else
        Chef::Log.info("Successfully uploaded config '#{configname}'")
      ensure
        puts "End of upload_default_config execution."
      end
    end

    def createCollection(coll_url,collection_name,num_shards,replication_factor,max_shards_per_node,conf_name)
      begin
        if (!"#{collection_name}".empty?) && (!"#{num_shards}".empty?) && (!"#{conf_name}".empty?) || (!"#{replication_factor}".empty?) || (!"#{max_shards_per_node}".empty?)
          Chef::Log.info("#{coll_url}?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{conf_name}")
          uri = URI("#{coll_url}?action=CREATE&name=#{collection_name}&numShards=#{num_shards}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}&collection.configName=#{conf_name}")
          output = Net::HTTP.get(uri)
        end
      rescue
        raise "Failed to Create collection. Config '#{configname}' may not exists."
      else
        Chef::Log.info("Successfully created collection")
      ensure
        puts "End of collection creation."
      end
    end

    def modifyCollection(coll_url,collection_name,autoAddReplicas,replication_factor,max_shards_per_node)
      begin
        if (!"#{collection_name}".empty?) && (!"#{autoAddReplicas}".empty?) || (!"#{replication_factor}".empty?) || (!"#{max_shards_per_node}".empty?)
          Chef::Log.info("#{coll_url}?action=MODIFYCOLLECTION&collection=#{collection_name}&autoAddReplicas=#{autoAddReplicas}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}")
          uri = URI("#{coll_url}?action=MODIFYCOLLECTION&collection=#{collection_name}&autoAddReplicas=#{autoAddReplicas}&replicationFactor=#{replication_factor}&maxShardsPerNode=#{max_shards_per_node}")
          output = Net::HTTP.get(uri)
        end
      rescue
        raise "Failed to modify collection."
      else
        Chef::Log.info("Successfully modified collection")
      ensure
        puts "End of modifying collection."
      end
    end

    def extractCustomConfig(solr_config,config_jar,config_url)
      delete_config = "sudo find . ! -name \"*.jar\" -exec rm -r {} \\;";

      remote_file "#{solr_config}/#{config_jar}" do
        source "#{config_url}"
        owner node['solr']['user']
        group node['solr']['user']
        mode '0777'
      end

      Chef::Log.info('Create Directory "#{solr_config}/prod"')
      directory "#{solr_config}/prod" do
        owner node['solr']['user']
        group node['solr']['user']
        mode '0777'
        action :create
      end

      Chef::Log.info('Unpack prod config files')
      bash 'unpack_prodconfig_jar' do
        code <<-EOH
          cd #{solr_config}
          mv #{config_jar} prod/
          cd prod
          #{delete_config}
          jar -xvf #{config_jar}
          sudo rm -rf #{config_jar}
        EOH
        not_if { "#{config_jar}".empty? }
      end
    end


    def setZkhostfqdn(zkselect,ci)
      cilocal = ci;
      if "#{zkselect}".include? "InternalEnsemble-SameAssembly"
        hostname = `hostname -f`
        fqdn = "#{hostname}".split('.')
        fqdn_string = "#{hostname}".split('.',6).last
        zk_host_fqdns = cilocal['platform_name']+"."+fqdn[1]+"."+fqdn[2]+"."+fqdn[3]+"."+fqdn_string
        node.set["zk_host_fqdns"] = zk_host_fqdns.strip;
      end

      if ("#{zkselect}".include? "ExternalEnsemble")
        node.set["zk_host_fqdns"] = cilocal['zk_host_fqdns']
      end

      return node['zk_host_fqdns']
    end

  end
end


