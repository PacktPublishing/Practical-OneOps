# Metadata for the redisio cookbook 
# Last Edited and Updated by Ravi Vangara
name             'Redisio'
maintainer       'Brian Bianco'
maintainer_email 'brian.bianco@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures redis'
version          '2.4.2'

#-cookie cutter grouping values
grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'src_url',
          :description => 'Source URL',
          :required => 'required',
          :default => 'http://download.redis.io/releases/',
          :format => {
              :help => 'location of the redis source distribution',
              :category => '1.Global',
              :order => 2
          }

### support freedom of choice
attribute 'version',
	:description => "Redis Version",
	:required => "required",
	:default => '3.0.1',
	:format => {
    		:category => '1.Global',
    		:help => 'Version of the Redis install',
    		:editable => true,
    		:order => 2
	}

### Number of Replicas in a Cluster - Default 1
attribute 'replicas',
	:description => "Number of Replicas for Cluster - Usually 1",
	:required => "required",
	:default => '1',
	:format => {
    		:category => '1.Version',
    		:help => 'Number of Replicas in the REDIS cluster',
    		:editable => true,
    		:order => 2
	}

# a description for each recipe, mostly for cosmetic value within the server UI
recipe "start", "Start Redis"
recipe "stop", "Stop Redis"
recipe "repair", "Repair Redis"
