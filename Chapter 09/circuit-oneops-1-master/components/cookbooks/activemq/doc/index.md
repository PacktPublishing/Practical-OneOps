#ACTIVEMQ USER'S GUIDE

ActiveMQ Server Pack is built on Apache ActiveMQ with out-of-the-box default settings for most options or properties. For a select few adjustable options or properties, this pack provides an OneOps GUI for users to specify the customized values. For details of a list of customizable properties or options, please refer to [ActiveMQ Server Pack GUI fields](#guifields).

For those properties or options not listed in the [ActiveMQ Server Pack GUI fields](#guifields) section, they all assume the default values directly from the Apache ActiveMQ product. Currently there is no mechanism provided to adjust those properties or options values. One can always manually change the settings of a ActiveMQ Server Pack server after it is provisioned by OneOps, but those manually changed settings will not survive a ActiveMQ Server Pack server redeployment. In other words, a manually changed setting on a ActiveMQ Server Pack server instance will be over written by a redeployment to its default value or the value specified in OneOps GUI.

ActiveMQ Server Pack supports all functionalities and features of Apache ActiveMQ for point-to-point and publish-subscription messaging except for revision of certain features and functionalities described in the next section.

If a functionality or feature is not described in this user's guide, one can assume that functionality or feature is inherited from Apache ActiveMQ. Users are advised to refer to [Apache ActiveMQ Documentation](http://activemq.apache.org/index.html).

Apache ActiveMQ is licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). You may not use ActiveMQ Server Pack except in compliance with the Apache License.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

###Features in ActiveMQ Server Pack

ActiveMQ Server Pack modified certain features and functionalities from standard Apache ActiveMQ.

1. View Only Admin Console:

  By default, ActiveMQ Server Pack provides a view only version of Apache ActiveMQ admin console. It does not support operations such as creating queues or topics, deleting or purging messages from queues, or sending messages to queues or topics. These operations through admin console bypasses OneOps deployment process, may result in ActiveMQ server state to be inconsistent to the record of truth in OneOps, thus is highly discouraged.

    If one creates a queue or topic via admin console, the created queue or topic is not in OneOps repository for the ActiveMQ Server Pack server instance, making the state of the server to be out of synch with the record of truth in OneOps. Further, the created queue or topic via the admin console will not survive a redeployment of ActiveMQ server, i.e. a redeployment of a ActiveMQ server instance will reset the server state to what is recorded in OneOps.

    Deleting or purging messages from a destination via admin console will not leave any audit trail in OneOps log, so this functionality is disabled in the admin console by default.

    Sending or publishing messages to a destination via admin console bypasses application logging mechanism; there would not be any records in application log files that messages were sent to a destination. For this reason, message production functionality is also disabled in admin console.

    All disabled operation functionalities can be enabled via ActiveMQ Server Pack GUI optional field "adhoc operations support". Users are encouraged to keep this disabled except for in application development environment.

2. Admin REST API Disabled

   Admin Rest API can provide the same operations as those in the admin console. For the same considerations, Admin Rest API is disabled by default.

     Users can enable the Admin Rest API in ActiveMQ Server Pack design. See "Adhoc Operations Support" in the [ActiveMQ Server Pack GUI fields](#guifields).

3. Security Mechanisms:

  ActiveMQ Server Pack supports the following authentication and authorization:

  1. None - no security.
  2. Simple - simple authentication and authorization.
  3. JAAS - properties file based JAAS authentication and authorization.

  Notably, LDAP authentication and authorization is currently **not** supported.

###Default ports for ActiveMQ Server

ActiveMQ server from this pack supports nio or tcp transport connector, and the default port is 61616. Users can add more transport connectors with port specifications, or modify the default nio or tcp transport connection port from 61616 to another port via ActiveMQ Server Pack design GUI in OneOps.

The admin console for ActiveMQ Server Pack is available on port 8161. Admin console port can be changed via ActiveMQ Server Pack design GUI.

JMX is available on 8099 over rmi port 1098. They are hard coded in ActiveMQ Server Pack cookbooks, and cannot be changed in this release.

##ActiveMQ Server Pack Components

<a name="activeMQPlatform"></a>
###ActiveMQ platform creation

For ActiveMQ server provisioning, one needs to create an OneOps assembly first so that an OneOps platform for ActiveMQ can be added to the assembly. Users are assumed to have operating knowledge of OneOps. For help with open source product OneOps, please refer to [OneOps Getting Started](http://oneops.github.io/user/getting-started/).

To add a ActiveMQ server platform to your assembly, in OneOps GUI, follow the following sample steps:

* Click on "Design",
* Click on "Create Platform",
* Provide values to the GUI fields, for example:

  * "Name" - "myActiveMQ"
  * "Description" - "this is my first activemq server design"
  * "Pack Source" - "oneops"
  * "Pack Name" - "ActiveMQ" under "Messaging"
  * "version" - 1

* Click "save", "commit", and "ok".

The platform "myActiveMQ" is created.

###Platform Components

After ActiveMQ platform is created, all ActiveMQ components will be available in the OneOps design page for the platform instance. Descriptions of ActiveMQ components are listed below:

**compute**

Your ActiveMQ instance(s) will be deployed on OneOps provisioned compute(s), so the first thing to customize in your platform design is the compute component.

The compute for ActiveMQ has a default size of "M" (medium), with 2 cores, 4 GB memory, and 20 GB ephemeral storage. If you want to change the compute size, you need to click on the "compute" component of your platform, and change the **instance size**.

**vol-data**

This is the default mount point for the kahaDB data directory for ActiveMQ server. It uses the ephemeral disk storage on the VM.

The default mount point for ActiveMQ is at /data directory; it is different from the ActiveMQ installation directory. Data directory being at a different location from the installation has the advantage of allowing the ActiveMQ server being updated, or rebuilt / redeployed without corrupting or losing the messages data.

It is strongly encouraged to specify the data directory to be at a different location from ActiveMQ installation directory as configuration changes in ActiveMQ could cause a re-build of the server instance by OneOps ActiveMQ cookbooks.

**volume**

This is for new mount points or new directories users define, using the ephemeral storage on the VM. It should be rarely used.

**storage**

The storage and volume set up is the next item that may need customization. Without changing anything in the storage or volume components, ActiveMQ server will use the ephemeral storage on the compute for the kahaDB. Data stored in the ephemeral store on the VM will be lost when the compute is replaced.

To prevent loss data on compute failure, external storage should be used for data store. After a storage component is added, a volume-externalstorage should be created to add mount point.

**volume-externalstorage**

To create a mount point for the external storage. For example, when Cinder storage is used for ActiveMQ data store, new mount point should be created to use the Cinder storage.

**user-activemq**

To access the compute where ActiveMQ server will be running on, user ssh keys should be added to the compute.  To add a user ssh key to the compute, edit the "user-activemq" component, in the "access" section of the "user-activemq" component, click the "add" button, and copy and paste user's ssh key, save and commit. This gives ssh access to the corresponding user to the compute as user "activemq".

After adding a user ssh key to the "user-activemq" component, the user can ssh to the ActiveMQ compute as user 'activemq' when deployment is done.

**secgroup**

This is for opening up compute ports. By default, the following ports are opened:

* 22 for ssh
* 61616 for tcp transport connector for ActiveMQ
* 61617 for ssl transport connector for ActiveMQ
* 8186 for ActiveMQ admin console
* 8099 for JMX
* 1098 for RMI used by JMX

Ports will NOT be automatically added in the secgroup component when ActiveMQ transport connectors are added in the ActiveMQ component.

**certificate**

This component is the ActiveMQ broker digital certificate in pkcs12 format. It is needed for SSL transport connector.

**keystore**

This component is the key store associated with a ActiveMQ broker instance. It is needed for SSL communication.

**share**

This component is for GlusterFS network-attached storage file system. It may be used by applications including cloud computing, streaming media services, and content delivery networks. It is not commonly used.

**queue**

This component is used for creating messaging queues on ActiveMQ server, and also assigning user permissions on queues if "simple" or "JAAS" authorization policy is specified for ActiveMQ server.

<a name="queuefields"></a>Following is a list of the **Queue GUI fields:**

  1. Queue Name

  Queue name is free entry, but by convention, destination names should be all uppercase; name tokens should be separated by a dot (.). The number of name tokens in a queue name is recommended to be at least 5 but less than 10.

  There should be some hierarchy structure in the queue or topic naming so that subject (name) based messaging is supported. For example, if a publishing application has the following name for two or more destinations, the structure of the names could be used by a consumer application to receive messages from all queues:

    * AMZ.Q.OMS.ORDER.CREATED.TXT
    * AMZ.Q.OMS.ORDER.FILLED.TXT
    * AMZ.Q.OMS.ORDER.RETURNED.TXT

  A consumer could use a name 'AMZ.Q.OMS.ORDER.>' to receive messages from all order queues.

  What characters can be used in a queue name and the length limit of a queue name is restricted by the underlining Apache ActiveMQ

  2. Destination Type

  Destination type for a queue can be either "Queue" for a regular queue or "CompositeQueue" for a virtual queue that forward messages to one or more physical queues or topics depending on the definition of the composite queue.

  When "CompositeQueue" is selected as the destination type, there will be a Composite Queue Definition text area added to the OneOps design GUI to define the composite queue.

  3. User permissions

  Queue permissions "Read" and/or "Write" can be granted to users. Click the "+add" button in the "User Permission" section in a queue design will add a user for permission grant. A user has to be defined in ActiveMQ "Broker Users" section. It is an error to grant permissions to a non-exist user (a user not defined in the "Broker Users" on ActiveMQ.

  Valid options for the permission field (second column after the "=" sign) are the following

    * R - readonly; Read permission grant user 'receive' permission on the queue
    * W - write only; Write permission grant user 'send' permission on the queue.
    * RW - read and write; 'send' and 'receive' permissions on the queue.

  A user with 'W' (write) permission is also granted 'admin' permission, meaning a user with 'W' permission can create the queue if the queue does not exist on the ActiveMQ.  A non-exist queue is created upon first access on ActiveMQ, this feature is inherited by ActiveMQ.

  4. Destination Policy

  Destination Policy can be defined for the given queue in the free entry text area. Following is an example of a destination policy for a queue named "my.test.queue.1":

  ```
  <policyEntry queue="MY.TEST.QUEUE.1"
    prioritizedMessages="true"
    useCache="false" expireMessagesPeriod="0" queuePrefetch="1" >
    <deadLetterStrategy>
        <individualDeadLetterStrategy
            queuePrefix="DLQ." useQueueForQueueMessages="true" />
    </deadLetterStrategy>
  </policyEntry>
  ```

  The above configuration demonstrates Activemq server with strict priority messaging on queue MY.TEST.QUEUE.1. It also shows an individual dead letter queue for MY.TEST.QUEUE.1 as DLQ.MY.TEST.QUEUE.1.

  If the policyEntry queue name does not match the name in the Queue Name field, the policyEntry in the destination policy text area will be ignored. It is a user error if the destination policy does not comply to the Activemq xml schema. If such user error occurs, the behavior of Activemq server may be nondeterministic, or it may not even be started.

  Please refer to Activemq documentation for more information on destination policies:
  http://activemq.apache.org/per-destination-policies.html

  5. Composite Queue Definition

  An optional field "Composite Queue Defination" may appear in OneOps GUI if the destination type is selected as CompositeQueue. This is a free entry text area for use to define the composite queue.

  Below is an example of a composite queue definition:

  ```
  <compositeQueue name="ORDER.QUEUE" forwardOnly="false">
      <forwardTo>
          <queue physicalName="ORDER.QUEUE-1" />
          <queue physicalName="ORDER.QUEUE-2" />
       </forwardTo>
  </compositeQueue>
  ```

  The above CompositeQueue definition will be inserted the destinationInterceptors -> virtualDestinationInterceptor -> virtualDestinations stanza of the broker element in Activemq.xml.  Please refer to Activemq documentation on virtual destinations at http://activemq.apache.org/virtual-destinations.html.

  If the compositeQueue name does not match the name in the Queue Name field, the composite queue definition will be ignored. It is a user error if the composite queue definition does not comply to the Activemq.xml schema. If such user error occurs, the behavior of Activemq server may be nondeterministic, or it may not even be started.

**topic**

This component is used for creating messaging topics on ActiveMQ server, and also assigning user permissions on topics if "simple" or "JAAS" authorization policy is specified for ActiveMQ server.

<a name="topicfields"></a>Following is a list of the **Topic GUI fields:**

  1. Topic Name

  Naming conventions for topics are similar to queues. The following is a sample topic:

  AMZ.T.IMS.ITEM.INVENTORY.XML

  There should be some hierarchy structure in the topic naming so that subject (name) based messaging is supported. For example, if a publishing application has the following name for two or more destinations, the structure of the names could be used by a consumer application to subscribe to all topics:

    * AMZ.T.OMS.ORDER.CREATED.TXT
    * AMZ.T.OMS.ORDER.FILLED.TXT
    * AMZ.T.OMS.ORDER.RETURNED.TXT

  A consumer could use a name 'AMZ.T.OMS.ORDER.>' to receive messages from all order topics.

  2. Destination Type

  Destination type for a topic can be either "Topic" for a regular topic, "CompositeTopic" for a virtual topic that forward messages to one or more physical queues or topics depending on the definition of the composite topic, or a "VirtualTopic" that define the topic to queues bridging for subscribers. A virtual topic can be considered as a special case of composite topic in that a virtual topic does not need to define the "forward to" destinations statically, in stead the activemq server will create a queue for each distinct subscriber based on subscriber name at runtime.

  When the destination type is CompositeTopic or VirtualTopic, an extra free entry text area will be rendered on the OneOps design GUI for use to define the CompositeTopic or VirtualTopic.

  3. User Permissions

  Permissions on topics are similar to those described for queues.

  4. Destination Policy

  Destination policy is a free entry text area for user to define the destination policy on the topic. Below is an example of a destination policy entry for a topic:

  ```
  <policyEntry topic="INVENTORY.XML">
        <dispatchPolicy>
            <strictOrderDispatchPolicy />
        </dispatchPolicy>
        <!--  1 minutes worth -->
        <subscriptionRecoveryPolicy>
            <timedSubscriptionRecoveryPolicy recoverDuration="60000" />
        </subscriptionRecoveryPolicy>
  </policyEntry>
  ```

  If the policyEntry topic name does not match the name in the Topic Name field, the policyEntry in the destination policy text area will be ignored. It is a user error if the destination policy does not comply to the Activemq xml schema. If such user error occurs, the behavior of Activemq server may be nondeterministic, or it may not even be started.

  5. CompositeTopic/VirtualTopic Definition

  When destination type is selected as CompositeTopic or VirtualTopic, an extra free entry text area will be rendered on OneOps design GUI to user to enter the CompositeTopic or VirtualTopic Definition.

  Here is an example of a virtual topic definition:

  ```
  <virtualTopic name="MY.SAMPLE.VT.1" prefix="VirtualTopicConsumers.*." selectorAware="false"/>
  ```
  Subscribers will get messages from dynamically created queues "VirtualTopicConsumers.{subscriberName}.My.SAMPLE.VT.1"

  There is a default class of virtual topic defined on Activemq server. The definition of the default virtual topic is that any topic whose name starts with 'VirtualTopic.' will be a virtual topic. Precisely, the definition of default virtual topics is below:
  ```
  <virtualTopic name="VirtualTopic.>" prefix="Consumers.*." selectorAware="false"/>
  ```
  Subscribers to any topic that starts with 'VirtualTopic.' will get messages from physical queues Consumers.{subscriber name}.VirtualTopic.{rest of topic name}.

  CompositeTopic is much the same as CompositeQueue.  Below is an example of a CompositeTopic:
  ```
  <compositeTopic name="MY.TOPIC">
    <forwardTo>
         <queue physicalName="FOO" />
         <topic physicalName="BAR" />
    </forwardTo>
  </compositeTopic>
  ```

  When the 'forwardOnly' attribute on a CompositeQueue is set to true, its behavior of the composite queue is the same as a CompositeTopic.

  CompositeTopic or virtualTopic definition will be inserted the destinationInterceptors -> virtualDestinationInterceptor -> virtualDestinations stanza of the broker element in Activemq.xml.  Please refer to Activemq documentation on virtual destinations at http://activemq.apache.org/virtual-destinations.html.

  If the compositeTopic name or the virtual topic name does not match the name in the Topic Name field, the definition of composite topic or virtual topic will be ignored. It is a user error if the composite topic or virtual topic definition does not comply to the Activemq.xml schema. If such user error occurs, the behavior of Activemq server may be nondeterministic, or it may not even be started.

**activeMQ**

<a name="guifields"></a>Following sections explain the **ActiveMQ GUI fields:**

Note: Fields with a star symbal is required, e.g. version*.

  1. Installation Directory

    ActimveMQ installation directory. Default to /opt

  2. version

    Version of Apache ActiveMQ to download. Default to 5.13.0.
    <a name="transportConnectors"></a>

  3. Transport Connectors

    Transport connector protocol and listen address and port.

    Default to ```nio://0.0.0.0:61616```

    You can add other transport connectors Apache ActiveMQ supports. Following is a list of sample transport connectors one could add:

    * ```amqp://0.0.0.0:5672```
    * ```stomp://0.0.0.0:61613```
    * ```mqtt://0.0.0.0:1883```
    * ```ws://0.0.0.0:61614```
    * ```ssl://0.0.0.0:61617```

    When a new port is used by ActiveMQ server, an entry should be added in the secgroup to enable connectivity on the port if the port is not already enabled.

  4. Log file Size (MB)

    Default to 5 MB. ActiveMQ maximum number of log files for rotation is hard coded at 5. So if the default log file size is used, there is a maximum of 25 MB log data for an ActiveMQ server instance.

  5. Log file path

    Default to /var/log/activemq

  6. Maximum Connections

    The number of maximum connections for each transport connector in a ActiveMQ server instance.

    Default to 1000.

  7. Environment Variables

    Environment variables for a ActiveMQ server instance. Multiple variables can be added.

  8. Enabled console authentication

    Flag to indicate authentication to access admin console is enabled or disabled.

    Default to enabled.

  9. Admin Username

    web console admin user name. Default to "admin".

  10. Admin Password

    web console admin user password. Default to "admin". Please change this password.

  11. Web Console Port

    web console port number. Default to 8161.

  12. JMX Username

    JMX user name. Default to "admin".

  13. JMX Password

    JMX user password. Default to "activemq". Please change this password.

  14. Adhoc Operations Support

    Flag for enabling or disabling admin console operations such as creating, deleting, or purging messages from destination. It is recommended to keep this feature disabled as those operations should be through OneOps; Enabling it will result in OneOps deployment out of synch with ActiveMQ.

  15. Admin REST API Support

    Flag for enabling or disabling Admin REST API. Enabling Admin REST API allows operations such as destination creation or deletion via Jolokia REST call. It is recommended to keep this feature disabled as actions via REST API will bypass OneOps, resulting in OneOps deployment out of synch with ActiveMQ.

  16. Enable password Encryption

    Flag for enabling or disabling password encryption for message users in users.properties.

  17. Beans Support

    A free entry text area for defining beans. Below is an example of a bean definition, paste the following to the free entry text area for Beans Support:

    ```
    <bean id="logQuery" class="io.fabric8.insight.log.log4j.Log4jLogQuery"
          lazy-init="false" scope="singleton"
          init-method="start" destroy-method="stop">
      </bean>
    ```

  18. Plugins Support

    A free entry text area for defining activemq plugins. Please refer to Activemq documentation on defining pluings.
    http://activemq.apache.org/xml-reference.html

    Following is an example of adding a plugin:
    Paste the following text in the free entry text area for Plugin Support field in OneOps GUI:

    ```
    <loggingBrokerPlugin logAll="true" logConnectionEvents="false"/>
    <timeStampingBrokerPlugin zeroExpirationOverride="1000" ttlCeiling="60000" futureOnly="true"/>
    <traceBrokerPathPlugin/>
    ```

    If redelivery plugin shall be used to define the redelivery policy on a given destination or for all destinations, a redelivery plugin configuration as below can be added in free entry text area of the plugin support:

    ```
    <redeliveryPlugin fallbackToDeadLetter="true" sendToDlqIfMaxRetriesExceeded="true">
        <redeliveryPolicyMap>
            <redeliveryPolicyMap>
                <redeliveryPolicyEntries>
                    <!-- a destination specific policy -->
                    <redeliveryPolicy queue="MY.TEST.QUEUE.1" maximumRedeliveries="4" redeliveryDelay="10000" />
                </redeliveryPolicyEntries>
                <!-- the fallback policy for all other destinations -->
                <defaultEntry>
                       <redeliveryPolicy maximumRedeliveries="5" initialRedeliveryDelay="5000" redeliveryDelay="10000"/>
                </defaultEntry>
            </redeliveryPolicyMap>
        </redeliveryPolicyMap>
    </redeliveryPlugin>
    ```

  19. KahaDB Attributes

    A key value hash for kahaDB configuration. Please refer to http://activemq.apache.org/kahadb.html

  20. Broker Attributes

     A key value hash for broker attributes configuration. Please refer to Activemq documentation on the set of broker attributes for a given version of Activemq, http://activemq.apache.org/xml-reference.html

  21. Init Memory (MB)

    Minimum heap size in MB of ActiveMQ server process. Default is 512 MB.

  22. Max Memory (MB)

    Maximum heap size in MB of ActiveMQ server process. Default is 2048 MB. It should be changed based on the VM instance size (M, L, 2XL, etc).

  23. Store Usage (MB)

    The storage size limit at which producers of persistent messages will be blocked. Default to 8192 MB.

  24. Temp Usage (MB)

    The temp storage size limit for non-persistent messages overflow to avoid out of memory issue. Default to 2048 MMB.

  25. Percent of JVM Heap %

    Percent of JVM Heap used for messages (message memory). Default to 60%.

  26. Enable SSL

    Enable or disable SSL transport for encrypted communication.

    To use SSL, SSL transport connector has to be specified. Please refer to [Transport Connectors](#transportConnectors).

    Certificate and Key store components have to be created.

  27. Enable SSL Client Auth

    If "Enable SSL" option is checked, then "Enable SSL Client Auth" option will become visible. This flag changes the SSL handshake requirement between ActiveMQ server and its client hosts.

    If "Enable SSL Client Auth" option on ActiveMQ is checked, then ActiveMQ server needs to have a trust store for client hosts certificates besides its own key store. The same is true on the client hosts which need to have their own trust store to store certificates of servers (in our case, the certificate of ActiveMQ server instances) besides a key store for client certificate.

    If "Enable SSL Client Auth" option on ActiveMQ is not checked, which is the default, then SSL between ActiveMQ and clients is by one way handshake. It means ActiveMQ server will trust all clients who request for SSL communication. Thus ActiveMQ only needs to have a key store for its own certificate; it does not need to have a trust store for any client certificate. On the client side, client hosts do not need to have their own key store, as no client certificate is needed for communicating with ActiveMQ server, however, client hosts do need to have a trust store for certificate of ActiveMQ servers.

    The two way handshake set up involves manual copying certificates about. It is difficult to automate the key store and trust store set up on both the client side and the server side. It is recommended to keep this flag disabled / unchecked unless two way handshake is necessary for safer SSL communication.

  28. Auth Type

    Authentication and authorization type. Default to JAAS.  Other options are "None" and "Simple".

    LDAP authentication and authorization is not supported in this release.

    For more information about ActiveMQ, please refer to [ActiveMQ Security](http://activemq.apache.org/security).

  29. Broker Users

    User name and password for authentication to ActiveMQ server instance for messaging. Mutliple users can be added.

    To add a user, click the "add" button for "Broker Users", enter username in the first column, and password for the user in the second column (after the "=" sign).

    ActiveMQ server owner (application team) is responsible for adding all messaging users in this configuration section. For instance, if the ActiveMQ owner team is a data producer on an application queue or topic, and some consumer client need to have a different username and password to connect to the same queue or topic on the ActiveMQ instance to consume messages, it is the ActiveMQ owner's responsibility to create the users on behalf of the consumer team. Coordination and cooperation between the producer application team and the consumer application team is assumed.

    For authorization to queues and topics, please refer to Queue and Topic components of the ActiveMQ platform.

  30. Binary distribution mirror urls

    Follow the link to get a list of [available mirror urls](http://www.apache.org/dyn/closer.cgi?path=).

  From the list of HTTP urls, copy a url without the last slash.  e.g. for site ```http://apache.arvixe.com/```, enter ```http://apache.arvixe.com``` in the "Binary distribution mirror urls*" field.

    Following mirror urls may be available:

   * ```http://apache.arvixe.com```
   * ```http://apache.mirrors.tds.net```
   * ```http://apache.claz.org/activemq```
   * ```http://apache.cs.utah.edu```
   * ```http://apache.go-parts.com```
   * ```http://download.nextag.com/apache```
   * ```http://mirror.olnevhost.net/pub/apache```
   * ```http://mirror.cc.columbia.edu/pub/software/apache```

    The mirror url is used as the first part of the ActiveMQ binary distribution download url. ActiveMQ pack constructs the whole download url with a fixed path to a version of ActiveMQ. e.g. For 5.13.0 ActiveMQ from ```http://apache.arvixe.com```, the complete url will be ```http://apache.arvixe.com/activemq/5.13.0/apache-activemq-5.13.0-bin.tar.gz```

  31. Binary distribution checksum

    MD5 checksum for downloaded ActiveMQ distribution file. It is used for verification of downloaded binary file.

    You can leave this field blank to skip the check sum verification of your downloaded ActiveMQ distribution file. The checksum verification is usually not needed and skipping it is harmless unless the downloaded file was corrupted during transmission.

**ActiveMQ Daemon**

This component is the watch dog process for ActiveMQ server on the deployed host. It can take some customized scripts for the daemon process to perform extra task. By default, the daemon process will manage the life cycle of ActiveMQ server process. Typically there is nothing for a user to change in this component.

##ActiveMQ Design and Provision

Following are the configuration steps in common use cases to configure Activemq. The steps and the configured items can be considered as the minimum using default values for most options and properties of ActiveMQ.

###CASE 1: Common Configuration

####Server Design

Let us assume a ActiveMQ platform named "myActiveMQ" is already created. Please follow [ActiveMQ platform creation](#activeMQPlatform) if one is not created yet.

On your OneOps assembly design page, click on your ActiveMQ platform "myActivMQ", then "edit".

Provide the following in the configuration:

* "Version": 5.13.0
* "Admin Password": admin123
* "JMX Password": admin123
* "Binary distribution mirror url": ```http://apache.arvixe.com````
* "Broker Users": appUser1 = appUser1Pwd

We will use the default values for all other fields. This complete the ActiveMQ Server design. We will be using properties file based JAAS authentication and authorization.

The ActiveMQ server will be deployed to a OneOps created VM on defaut tcp port 61616.

####Queue and Topic

Let us create a queue and a topic.

In OneOps design page for "myActiveMQ" platform, click the "+" button next to the "queue" component to add a new queue.

Entery the following for the queue design:

* "Name": mytestqueue1
* "Queue Name": AMZ.Q.NYTEST.QUEUE.1

Click on the "+add" button in the "User Permission" section.

add "appUser1" in the first column and "RW" in the second column.

Similarly create a topic with the following:

* "Name": mytesttopic1
* "Topic Name": AMZ.T.NYTEST.TOPIC.1

assign "RW" permission to user appUser1 on WMT.T.NYTEST.TOPIC.1

####SSH Key

For a user to be able to log on to the VM compute, the user needs to add his or her ssh key to the "user-activemq" component.

On the design page for "myActiveMQ", click on the "user-activemq" instance, then "edit":

click the "+add" button in the "access" section to add an "Authorized keys" entry, copy and paste a customer's ssh key. Multiple keys can be added if more than one person need to log on to the ActiveMQ server host.

####Deployment

In OneOps transition, we add a new environment, and select compute from the cloud.

* "Name": test
* "Availability Mode": single
* select one 'primary' from the available clouds.

save, commit, and deploy.

If everything goes well, you should have a ActiveMQ instance up and running on a VM somewhere in the cloud you selected when you created your environment.

####Verification

In the 'operations' page, you should be able to find a compute instance after a successful deployment. You should be able to find the ip address of your compute where the ActiveMQ instance is running. Let us assume your VM has ip address 1.2.3.4, and you added your ssh key to the "user-activemq" component before your deployment.

You should be able to logon to the VM host via ssh:

    ssh activemq@1.2.3.4

After you log on to the compute, you should be able to see two running processes for user 'activemq': one is the wrapper process, and the other is the ActiveMQ process itself.

Verify directories:

* installation:  /opt/activemq
* data: /data/kahadb
* log: /var/log/activemq

You can run command line utilitity activemq for messaging:

/opt/activemq/bin/activemq producer --brokerUrl tcp://localhost:61616 --user appUser1 --password appUser1Pwd --destination queue://AMZ.Q.NYTEST.QUEUE.1 --message "this-is-a-test" --messageCount 1

/opt/activemq/bin/activemq consumer --brokerUrl tcp://localhost:61616 --user appUser1 --password appUser1Pwd --destination queue://AMZ.Q.NYTEST.QUEUE.1 --messageCount 1

You can log on to the admin console: ```http://1.2.3.4:8161/admin``` and verify presence of queues and topics, message counts, and browse queue messages.

###CASE 2: ActiveMQ with SSL

To use SSL transport connector in ActiveMQ, extra steps in design are needed. This chapter try to capture the extra steps or components needed for SSL.

####ActiveMQ Server design

* add transport connector:

  "ssl"  = "ssl://0.0.0.0:61618"

* enable ssl

  check "Enbable SSL" option field

* disable "Enable SSL Client Auth"

  keep it unchecked

* specify key store path

  "Keystore absolute path", default to $OO_LOCAL{keystorepath}

* specify key store password

  password for the key store.

####secgroup component

   add ssl port 61618 to the secgroup component.

   add to "Inbound rules":
   61618 61618 tcp 0.0.0.0/0

####platform variables

* Click on "Design",
* click on your ActiveMQ platform. e.g. "myActiveMQ",
* click on "Variables"

edit the following variables, provide appropriate values:

* keystorepath

####key store

   add key store, provide keystore password

####certificate

1. use keytool to generate a certificate and store it in a pkcs12 keystore

   keytool -genkey -alias broker -keyalg RSA -keystore mybroker.p12 -storetype pkcs12

   password for keystore: secret

   fill out the fields that follows on screen.

2. use openssl to view the private key and the certificate

   openssl pkcs12 -in  mybroker.p12 -nodes
   Enter Import Password: secret

   Below is a printout of one sample self signed certificate. If you do not want to create your own for testing out SSL of ActiveMQ server, you can use the private key and certificate directly.

   ```
   -----BEGIN PRIVATE KEY-----
   MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCBKo17IznYmpXl
   /WjceXb7o2rTODCbREpu4x12sGJP8AE56II+pmMEi3RfAGYF2Tyh6/jaYl/UlW1l
   an6zuHGbIUOi0WuVQpiq3YW2TjxEMTbSCqc+dE5W1yhA8UpKTWBAfVXgCp2rRlkT
   /T0OHKUPYYpDpy3o2xNIcQx2/1rTJDug7++F0GjEAtN4B6yttP73rRZp0Cs2cyGT
   VL3z5tej1idj0T2xjViWuLrRTXHK2DaoryvZpRbQ6vHsVfzOz497faRCNj3SkDNj
   Mn0rl483lOxx+tf5S/o3fzMQBj+VL6T0oK2cIIehbHzoNPc7WHqnKmh9zTa3SyYs
   6704nQ8XAgMBAAECggEAJJdveUDjdE9mw77kZAEtCeCjtK6oZnQUOhGxGRyi3U56
   qnMJ4sG0L2dqUjeEr4d5O83js8pGp6ylTyO6PSO1W2MzC/8T4Tb6lP0okhrby929
   UAeglXrRbpyJVMyGZUJCUEKxf0TCofDN73HASC0pPZA+YSgNQ3g8oDsWcueoTUQA
   iq0cKiEet1D8xPNp3gpDL9du5IRmpSpb8wrxM47WQU400GXHalxUz3Bgx1PIobB8
   rkeJCt+L8qBA69TXkgTu0f/JF7yuKXsd5VrGzpDAlepXv/TtfoWEv9rdtR6vb3WD
   /hL9Q38M/wy22T9tmEozaOe0w5jgHZeT+qqfb4tsgQKBgQDPgSSQyWyXgXnd0shN
   nLWP5+dgiJD6dbpVupb2JC0ILxzRiPXrcGARFPZY+p8ho/ol1OgJNK4jZ8kVbBoK
   RTvC1KyfcgGl0ZT8ae7SifTvDIenurhSIi0b/rEQWpqbSUje1vs6UJ1bbw8R6nGp
   zzwTJgY544K4ZKOYja2Brn1pNwKBgQCfWnvTV9pcTHB4QJ2QaOKEEvZ0/b5xkMBI
   LF73Zyb2wGrSOFz2+Mo7rev3OpXvcg4nyd/oufhtvbyTgK29VDVV6yUIIRCwhJAA
   uP/9WEIW2gRWhtMlTMBX2K0TkaW2P1AnfzOCl/rZ7qqp0BdRnjGyuFXvoDKPcSGy
   7kV018T5IQKBgQCZV9dcw+1i3QThH3Z0nH00Fm1PUjzJShzkY5pR1ZQNuzsxwWPy
   lD36AaK3SKY2ZwZh1L+QpgSWF4lrMlLgCh/Kr/3NaqO7FXFjQymBHwAJdBn/oqW5
   1JW/XW0eJ8afQP3/56EKjC5tNlpNpBJRKds8T1pEh1O/zmdzQifZcMgu6wKBgBUJ
   kQdZtc4xmTeG8EY8Uos1JaxUQ2wiu//LO85Vo+M3i+Ks5jkEp04xq9E7vseZuxyt
   ng3PX2i9f8PJXSZ9k30ASidEljt3hLtTsRf1KuRxa9kwe3eVJl9yj4bh14qz2RUd
   yeMXxVo4E/fPLQTtaYo6o7263HHrcZN5uVmvkqWBAoGAWkexnZZU7Je58UwW+0Br
   Qi4Z3Mb1OD0z+oM7WxKm4ABHWDTw3RaEP3AiLz2nXNZ8B3Hifmmwma+M5XIcweVw
   AvCRzv64+QA1m4jIsXyuQlWCgejBSOw1ghtRprd3EkunFzRN7D3fWWVQungun4nx
   XG+JcWVPIfAK9zeBxu8PLYo=
   -----END PRIVATE KEY-----

   -----BEGIN CERTIFICATE-----
   MIIDhDCCAmygAwIBAgIDP/XWMA0GCSqGSIb3DQEBCwUAMHMxCzAJBgNVBAYTAlVT
   MRMwEQYDVQQIEwpjYWxpZm9ybmlhMRIwEAYDVQQHEwlzdW5ueXZhbGUxEDAOBgNV
   BAoTB3dhbG1hcnQxEDAOBgNVBAsTB3BsYXRvcm0xFzAVBgNVBAMTDkwtU0I4QzJF
   WkczUS1NMB4XDTE2MDMyNTE3MjE1M1oXDTE2MDYyMzE3MjE1M1owczELMAkGA1UE
   BhMCVVMxEzARBgNVBAgTCmNhbGlmb3JuaWExEjAQBgNVBAcTCXN1bm55dmFsZTEQ
   MA4GA1UEChMHd2FsbWFydDEQMA4GA1UECxMHcGxhdG9ybTEXMBUGA1UEAxMOTC1T
   QjhDMkVaRzNRLU0wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCBKo17
   IznYmpXl/WjceXb7o2rTODCbREpu4x12sGJP8AE56II+pmMEi3RfAGYF2Tyh6/ja
   Yl/UlW1lan6zuHGbIUOi0WuVQpiq3YW2TjxEMTbSCqc+dE5W1yhA8UpKTWBAfVXg
   Cp2rRlkT/T0OHKUPYYpDpy3o2xNIcQx2/1rTJDug7++F0GjEAtN4B6yttP73rRZp
   0Cs2cyGTVL3z5tej1idj0T2xjViWuLrRTXHK2DaoryvZpRbQ6vHsVfzOz497faRC
   Nj3SkDNjMn0rl483lOxx+tf5S/o3fzMQBj+VL6T0oK2cIIehbHzoNPc7WHqnKmh9
   zTa3SyYs6704nQ8XAgMBAAGjITAfMB0GA1UdDgQWBBS1PVEj+JM/9XbqtXoQiNUy
   vD2b2jANBgkqhkiG9w0BAQsFAAOCAQEAKvw8/GzrUVv8G8hIrXWpogfN10m5+vQ8
   Uuh+I2AgMybjjD14519aBJ60g563Nn9hKS9yDxJ2eQnJ5S37I2z68JGJJh0pNmeC
   GstDHw9+w6GIw4M+/Xf9xx/91H4AwLh1KzB0w8RbcElqwJZgIdDvZGqNV/7Y/tWe
   07qQ4UWEEkkhHK59Lq6dsvkNS77cZr0Bye/m2ya/2tWf+QMUjzh7m241DWcHat/0
   JmIrH8VMhmJ7oc2rV9PJDSbfzVU4rjzM8pcOkCGR4I279R6y5Vs263NkA7ndx0gp
   PdWDez0rE4OJvtfhFY1/pQp+Oe8SzlDoXEEHuKV8cE+i/XXHnKxEow==
   -----END CERTIFICATE-----
   ```

3. Add the certificate

    * Copy and paste the private key to the "key" area
    * Copy and paste the certificate to the "certificate" area and the "SSL CA certificate key" area
    * Enter the password used when the certificate was created in the "Pass Phrase" area: secret
    * Check the "Convert to PKCS12" option.

    save

####Client Trust Store set up

  Once SSL components design are complete, and deployed successfully, ActiveMQ server instances provisioned will be available for SSL communication.

  On the client host, you need to create a trust store for the ActiveMQ server certificate. Use the keytool for importing ActiveMQ server certificate into client trust store.

####Verification

   After client host has the trust store and ActiveMQ server have the SSL setup, client host and ActiveMQ can communicate via SSL.

   To verify, you can log on to the ActiveMQ host, and check the configuration file of activemq.xml, verify "activemq" server process is up and running.

   From your client host, you can logon to the admin console via https:  ```https://1.2.3.4:61618/admin```

   Assuming your have a local ActiveMQ installation on the your desktop, and you can run the "activemq" command line. Also assume you have set up a trust store that has certificate of ActiveMQ server instance from 1.2.3.4:61618.

   You can verify SSL of ActiveMQ as follows:

   ./activemq producer --brokerUrl ssl://1.2.3.4:61618 --user appUser1 --password appUser1Pwd --destination queue://AMZ.Q.NYTEST.QUEUE.1 --message "this-is-a-test" --messageCount 1 -Djavax.net.ssl.trustStore=/path/to/mytrust.jks -Djavax.net.ssl.trustStorePassword=secret

   Similarly, you can run a command line consumer as well to verify messaging over ssl.


## ActiveMQ Operations

OneOps GUI provide built in action panels that ActiveMQ pack implement for server start, stop, restart, repair operations.

Users are encouraged to manage ActiveMQ server life cycle via OneOps operations page.

## FAQ's

1. What is Durable Subscription and how to use Durable Subscription?
````
A subscriber (also known as a consumer) is an application that creates a subscription to receive publications (or messages) from desired topic(s).
There are two types of subscribers:
    * Non-Durable subscriber: This type of subscriber application will get publications from a messaging provider as long as the application is running. Once the application ends, the messaging provider removes the subscription.
    * Durable Subscriber: This is the second type of application which receive publications as long as they are running. When the application ends, the messaging provider will cache publications for the subscriber and deliver them when the application comes back.

             ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory( "username", "password", "hostname:port");
            // Create a Connection
            Connection connection = connectionFactory.createConnection();
            // Set client Id
            connection.setClientID(clientId);
            // Create a Session
            Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
            //create topic
            Topic topic = session.createTopic("TOPICTEST");
            // create durable subscriber
            MessageConsumer  consumer = session.createDurableSubscriber(topic, "sub3");
            connection.start();
            //consumer read messages
````

