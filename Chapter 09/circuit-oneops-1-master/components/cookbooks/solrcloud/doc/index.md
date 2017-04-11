# SolrCloud Cookbook


SolrCloud Pack is a platform service that makes it easy to set up, manage, deploy, operate and scale solrcloud as a search solution for your web application in private and public clouds. You can set up and configure your Solrcloud cluster in minutes from the ONEOPS and enables you to monitor and resize your cluster up or down. As your volume of data and traffic fluctuates, the pack automatically scales to meet the rapidly scaling search requirements. The pack monitors the solution to ensure that a) it has sufficient resources, and that b) it is not consuming too many resources. With the SolrCloud platform you do not have to manage multiple pieces of software, manually configure, design a replication and high-availability strategy, provision hardware, scale your search engine, or recover failed nodes. The environment is automatically kept up-to-date and provide maintenance and support of the solution and reduces the the time to configure and implement the SolrCloud search solution.


Apache Solrcloud is an open source enterprise search platform, written in Java. SolrCloud Pack installs any version of the apache solrcloud ( 4.x.x, 5.x.x, 6.0.0 ). The solrcloud pack installs solr as a war in a tomcat web container for 4.x.x versions and as a standalone server for 5.x.x , 6.x.x versions etc.

The objective of this document is to guide the solrcloud pack installation with Internal/External/Embedded zookeeper cluster mode based on the user selection and uploads the default config to the zookeeper and gets started. The assumption is that the zookeeper is already installed and ready if the user choose the External Ensemble. The zookeeper and the solrcloud gets install at once for Internal Ensemble (same assembly) option.

Please note that the actions in the operation phase are not used for the solrcloud with embedded zookeeper mode. It is a local installation with a single zookeeper instance running locally. We need to do all actions through command line or solrcloud REST APIs.




## Supported features in the solrcloud pack

### SolrCloud Pack features:

The following are the current features built into the OneOps pack. This will be updated as we release new features in the pack. The documentation is built into the pack.

  * Collection Actions(create/modify) - These are the 2 actions on collection built into the pack. These actions will be enhanced to provide high availability and distribute replicas across the clouds/availability zones.
  * Monitoring and Alerting -
    * Processes - OneOps monitors have been set to track SolrCloud and Zookeeper processes. Alerts are generated if the processes stop running.
  * Lifecycle Automation-
    * OneOps integration - The pack leverages OneOps Auto-Repair automatically and Auto-Replace to handle failure scenarios manually by each node. The pack has provided a feature (join the replaced node) to the cluster. Depending on the maxShardsPerNode parameter, this feature chooses the shards which has least no of replicas and adds the replaced node as a replica for the list of collections provided in the pack. User should replace each node at a time and can verify whether the node joined as a replica to the cluster.
    * OneOps Auto sizing - Currently, the pack can scale up the nodes and installs the solrcloud. User can use the action (addReplica) to join the newly added nodes to the cluster of particular shard.



# Installation Steps

* Create an Assembly
  * GoTo oneops web link and create assembly .
#### Design Phase
 * Add a New Platform.
 * Choose SolrCloud from the pack source.
 * Click on the user-app Component and add the developers ssh keys.

   ###### Note
   If you want to deploy solr-4.x.x version then update the required parameters of the"tomcat" component else ignore the tomcat component configuration.

 * Click on the tomcat component.
   ##### Tomcat Component Parameters
   * Java_Options : Add/Update the JVM parameters.
   * Access Log Parameters : Add/Update the access log parameters in this section . You can add the values to enable the access logs and delete the values to disable the access logging.

 * Click on the solrcloud component.
   ##### Solrcloud component parameters
     * Solr Base url : Use the given default value.
     * Solr Binary Distribution package type : Select "solr" always.
     * Solr Binary Distribution format : select "tgz" format always.
     * Solr Binary Distribution version : Choose the required version.
     * default configname  : Update if required.
     * url of custom solr config - Give the download path of config with .jar extension.
     * custom configname - Give the custom config name for the custom config jar.

     Additional parameters for solr-5.x/solr-6.x version in the section "SolrCloud Standalone server Paramerters".

     ##### SolrCloud stand alone server parameters section
      * installation_dir_path
      * data_dir_path
      * port_no
      * gc_tune_params
      * gc_log_params
      * solr_opts_params
      * solr_max_heap
      * solr_min_heap

     ##### Zookeeper section
      There are 2 options:
      * External Ensemble - The assumption is that zookeeper is deployed and running.
        Parameters:
        External ZK hosts: Provide the external zookeeper "fqdn" address
      * Internal Ensemble: The assumption is that both the solrcloud and zookeeper platforms are added to the design.
        Parameters:
        Platform Name: Provide the platform name of the zookeeper which is given in the design phase
        This feature will auto discover the zookeeper fqdn and both the solrcloud and zookeeper platforms need to be deployed together.

 * Commit the design.

#### Transition Phase
 * Create an environment and pull the design into transition phase .
 * Choose the redundant mode and update the scaling values .
 * We can update the components (for ex: solrcloud,tomcat,user-app etc.,) in the transition phase and then needs to be locked .
 * Changes to "lb" Component
    * Goto "lb" component and 
      * update the listener from "http 80 http 8080" to "tcp 8983 tcp 8983" from solr 5.x.x version onwards based on the port you choose to deploy solrcloud.
      * update the ECV check.


#### Operation Phase

##### SolrCloud component Action Items
* createCollection - Creates the collection.
  * Parameters
    * collectionname - Give the collection name
    * numShards - Give the no of shards
    * replicationFactor - Give the replcationFactor
    * maxShardsPerNode - Give the max shards per node
    * configname - Give the config name which is uploaded to zookeeper.
* addreplica - Adds the selected node as a replica to the given shard of a collection.The ADDREPLICA action in the pack allows to host a replica of one copy for the given shard and collection.
  * Parameters:
    * collectionname - Collection name
    * shardname - shard name
* modifycollection - Modifies collection.
* updateclusterstate - Removes dead replicas and updates the cluster state to zookeeper.
* uploadsolrconfig - Uploads the custom config to zookeeper.
  * Parameters:
    * CustomConfigJar - Custom config jar nexus path.
    * CustomConfigName - Custom config name.
* dynamicschemaupdate - Updates managed schema and uploads to Zookeeper. It returns immediately if the timeout parameter is not set and the remaining cores get the latest schema asynchronously. This action reloads the core automatically and uses the latest schema from the next request onwards.
  * Parameters:
    * collectionname - Collection name.
    * modify_schema_action - Action to add/replace/delete field/field-type/dynamic-fields/copy-fields on the managed schema.
    * payload - payload of the action.
    * updateTimeoutSecs - Timeout for the request to wait and make sure that all the replicas/cores retrieves the changes of the managed schema.
* configupdate - Updates the solr-config and uploads to Zookeeper.
  * Parameters:
    * collectionname - Collection name.
    * common_property - Basic property to set the value.
    * value - Value of the property.
* start - Start the solrcloud
* stop - Stop the solrcloud
* restart - Restart the solrcloud
* status - Print the status of solrcloud in the log.




# Update the Installation

    ##### solr-4.x.x version
    * To update the zookeeper connection string -  Update the zookeeper fqdn string in the solrcloud component and do touch and deploy both the "tomcat" and "solrcloud" components.
    * Directory structure of pack installation
    ```      
    /{use-app}/solr-config
    /{use-app}/solr-config/default
    /{use-app}/solr-config/prod
    /{use-app}/solr-war-lib
    /{use-app}/tomcat7
    /{use-app}/tomcat7/logs
    /{use-app}/solr-cores/solr.xml
    ```

    ##### solr-5.x.x/6.x.x version
    * To update the zookeeper connection string -  Update the zookeeper fqdn string in the solrcloud component and do touch and deploy the solrcloud component.
    * Directory structure of pack installation
    ```
    /{installation_dir_path}/solr-config{solr_major_version}
    /{installation_dir_path}/solr-config{solr_major_version}/default
    /{installation_dir_path}/solr-config{solr_major_version}/prod
    /{installation_dir_path}/solr-war-lib{solr_major_version}
    /{installation_dir_path}/solr{solr_major_version}
    /{installation_dir_path}/solrdata{solr_major_version}
    /{installation_dir_path}/solrdata{solr_major_version}/data
    /{installation_dir_path}/solrdata{solr_major_version}/data/solr.xml
    /{installation_dir_path}/solrdata{solr_major_version}/logs
    ```



