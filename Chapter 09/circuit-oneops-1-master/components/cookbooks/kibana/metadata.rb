name                'Kibana'
description         'Installs/Configures Kibana'
version             '1.0'
maintainer          '@WalmartLabs'
license             'Copyright Walmart, All rights reserved.'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom'],
         :namespace => true

attribute 'src_url',
          :description => 'Source URL',
          :required => 'required',
          :default => 'https://download.elastic.co/kibana/kibana/',
          :format => {
              :help => 'location of the redis source distribution',
              :category => '1.Global',
              :order => 2
          }

attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default => '4.1.2',
          :format => {
		:important => true,
              	:help => 'Version of ElasticSearch',
              	:category => '2.Global',
              	:order => 1,
              	:form => { 'field' => 'select', 'options_for_select' => [['4.1.2', '4.1.2'], ['4.2.2', '4.2.2'], ['4.3.2', '4.3.2'], ['4.5.1', '4.5.1'], ['4.5.4', '4.5.4'], ['4.6.1', '4.6.1']] }
          }

attribute 'install_path',
          :description => 'Installation Directory',
          :required => 'required',
          :default => '/app/kibana',
          :format => {
              :important => true,
              :help => 'Install directory of ElasticSearch',
              :category => '2.Global',
              :order => 1
          }

attribute 'port',
          :description => 'Kibana Port',
          :required => 'required',
          :default => '5601',
          :format => {
              :important => true,
              :help => 'Kibana service Port',
              :category => '2.Global',
              :order => 1
          }

attribute 'elasticsearch_cluster_url',
          :description => 'ElasticSearch Cluster FQDN including PORT - http://eserver:9200',
          :required => 'required',
          :default => 'http://testcluster.com:9200/',
          :format => {
              :important => true,
              :help => 'Name of the elastic search cluster',
              :category => '2.Cluster',
              :order => 1
          }

recipe 'start', 'Start Kibana'
recipe 'stop', 'Stop Kibana'
recipe 'restart', 'Restart Kibana'
