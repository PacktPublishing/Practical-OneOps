# Solrcloud Cookbook


SolrCloud Pack is a platform service that makes it easy to deploy, operate solrcloud in the private and public clouds. You can set up and configure your Solrcloud cluster in minutes from the ONEOPS and enables you to monitor and resize your cluster up or down.





## Attributes

### SolrCloud
```
* solr_url
* solr_package_type
* solr_format
* solr_version
* replace_nodes
* config_name
* custom_config_url
* custom_config_name
* installation_dir_path
* data_dir_path
* port_no
* GC_TUNE_params
* GC_LOG_params
* SOLR_OPTS_params
* solr_max_heap
* solr_min_heap
```

### Zookeeper
```
* zk_select
* zk_host_fqdns
* num_instances
* port_num_list
* datacenter_ring
* cloud_ring
* platform_name
* env_name
```


## Usage
  _solrcloud::add_
  _solrcloud::update_


## Contributing
1. Fork the repository on Github
1. Create a named feature branch (like `add_component_x`)
1. Write you change
1. Write tests for your change (if applicable)
1. Run the tests, ensuring they all pass
1. Submit a Pull Request using Github




## License and Authors



