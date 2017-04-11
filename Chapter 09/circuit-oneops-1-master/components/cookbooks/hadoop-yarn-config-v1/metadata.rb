name 'Hadoop-yarn-config-v1'
maintainer '@WalmartLabs'
maintainer_email 'dmoon@walmartlabs.com'
description 'Hadoop YARN Configurations (v1 build)'
long_description 'Hadoop YARN Configurations (v1 build)'
version '1.0.0'

grouping 'default',
         access: 'global',
         packages: ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'hive_config_only',
          description: 'Hide all configs that do not pertain to configuring a hive client',
          default: 'true',
          format: {
              category: '1.Hive Client',
              help: 'Uncheck this box to configure all yarn attributes',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'ganglia_servers',
          description: 'Ganglia Server(s)',
          required: 'required',
          default: '127.0.0.1:8649',
          format: {
              category: '2.Monitoring',
              filter: { 'all' => { 'visible' => 'hive_config_only:eq:false' } },
              help: 'Specify ganglia servers to point metrics to.',
              order: 2
          }


#           _       _           _
#      __ _| | ___ | |__   __ _| |
#     / _` | |/ _ \| '_ \ / _` | |
#    | (_| | | (_) | |_) | (_| | |
#     \__, |_|\___/|_.__/ \__,_|_|
#     |___/
#     global

attribute 'show_global_properties',
          description: 'Show global hadoop properties',
          default: 'false',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'hive_config_only:eq:false' } },
              help: 'Check this box only if you want to view or change the default global hadoop properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'yarn_tarball',
          description: 'Location of yarn tarball',
          required: 'required',
          default: 'tarball_url',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Full URL to grab installation tarball from',
              order: 2
          }

attribute 'force_yarn_reinstall',
          description: 'Download and re-install yarn regardless of if the version of the tarball specified above is already installed',
          default: 'false',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Typically on a re-deployment, yarn will only be re-installed on an upgrade, this option forces a re-deployment',
              order: 3,
              form: { 'field' => 'checkbox' }
          }

attribute 'hadoop_install_dir',
          description: 'Hadoop Installation Directory',
          required: 'required',
          default: '/opt',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Base directory of where Hadoop will be installed',
              order: 4
          }

attribute 'hadoop_user',
          description: 'Username to run as',
          required: 'required',
          default: 'yarn',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'The username the services will run as',
              order: 5
          }

attribute 'hadoop_datanode_opts',
          description: 'Java Datanode Options',
          required: 'required',
          default: '-Xmx1000m',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'This option sets the HADOOP_DATANODE_OPTS in hadoop-env.sh',
              order: 6
          }

attribute 'hadoop_namenode_opts',
          description: 'Java Namenode Options',
          required: 'required',
          default: '-Xmx1000m',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'This option sets the HADOOP_NAMENODE_OPTS in hadoop-env.sh',
              order: 7
          }

attribute 'hadoop_heapsize',
          description: 'Max Hadoop Heapsize in MB',
          required: 'required',
          default: '1000',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'This option sets the HADOOP_HEAPSIZE in hadoop-env.sh',
              order: 8
          }

attribute 'hadoop_namenode_init_heapsize',
          description: 'Max Hadoop Namenode Init Heapsize in MB',
          required: 'required',
          default: '1000',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'This option sets the HADOOP_NAMENODE_INIT_HEAPSIZE in hadoop-env.sh',
              order: 9
          }

attribute 'additional_libraries',
          description: 'additional libraries to be installed',
          required: 'required',
          default: 'somejars',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'These libraries will be installed in the hadoop library paths',
              order: 10
          }

attribute 'zk_hosts',
          description: 'Zookeeper Hosts for HA',
          required: 'required',
          default: 'zk_hosts',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Specify zookeepers to be used for high availability',
              order: 11
          }

attribute 'extra_yarn_site',
          description: 'Custom yarn-site.xml properties',
          data_type: 'text',
          default: '',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Extra properties to be added to yarn-site.xml',
              order: 12
          }

attribute 'extra_core_site',
          description: 'Custom core-site.xml properties',
          data_type: 'text',
          default: '',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Extra properties to be added to core-site.xml',
              order: 13
          }

attribute 'extra_mapred_site',
          description: 'Custom mapred-site.xml properties',
          data_type: 'text',
          default: '',
          format: {
              category: '3.Global',
              filter: { 'all' => { 'visible' => 'show_global_properties:eq:true' } },
              help: 'Extra properties to be added to mapred-site.xml',
              order: 14
          }

attribute 'use_all_cores',
    :description => "EXPERT MODE ONLY: use all cores",
    :default => 'false',
    :format => {
        :category => '3.Global',
        :filter => {'all' => {'visible' => 'show_global_properties:eq:true'}},
        :help => 'Use all cores on a compute- will not reserve any for the system.  Do not use unless you are sure you know what you are doing as performance may be affected',
        :order => 15,
        :form => {'field' => 'checkbox'}
}

#     _         _  __               _ _
#    | |__   __| |/ _|___       ___(_) |_ ___
#    | '_ \ / _` | |_/ __|_____/ __| | __/ _ \
#    | | | | (_| |  _\__ \_____\__ \ | ||  __/
#    |_| |_|\__,_|_| |___/     |___/_|\__\___|
#    hdfs-site

attribute 'show_hdfs_properties',
          description: 'Show hdfs properties',
          default: 'false',
          format: {
              category: '4.hdfs Properties',
              filter: { 'all' => { 'visible' => 'hive_config_only:eq:false' } },
              help: 'Check this box only if you want to view or change the default hdfs properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'hdfs_namenode_name_dir',
          description: 'dfs.namenode.name.dir',
          required: 'required',
          default: '/work/hdfs/namenode',
          format: {
              category: '4.hdfs Properties',
              filter: { 'all' => { 'visible' => 'show_hdfs_properties:eq:true' } },
              help: 'dfs.namenode.name.dir',
              order: 2
          }

attribute 'hdfs_datanode_data_dir',
          description: 'dfs.datanode.data.dir',
          required: 'required',
          default: '/work/hdfs/datanode',
          format: {
              category: '4.hdfs Properties',
              filter: { 'all' => { 'visible' => 'show_hdfs_properties:eq:true' } },
              help: 'dfs.datanode.data.dir',
              order: 3
          }

attribute 'extra_hdfs_site',
          description: 'Custom hdfs-site.xml properties',
          data_type: 'text',
          default: '',
          format: {
              category: '4.hdfs Properties',
              filter: { 'all' => { 'visible' => 'show_hdfs_properties:eq:true' } },
              help: 'Extra properties to be added to hdfs-site.xml',
              order: 4
          }

#                  _  __ _
#     _____      _(_)/ _| |_
#    / __\ \ /\ / / | |_| __|
#    \__ \\ V  V /| |  _| |_
#    |___/ \_/\_/ |_|_|  \__|
#    swift

attribute 'show_swift_properties',
          description: 'Show swift properties',
          default: 'false',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'hive_config_only:eq:false' } },
              help: 'Check this box only if you want to view or change the default swift properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'swift_tmp_dir',
          description: 'hadoop.tmp.dir',
          required: 'required',
          default: '/work/tmp',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              help: "Specify the local file system location for temporary files. Used as a base for temp directory on ephemeral HDFS as well. To override for HDFS temp, use the 'custom core-site.xml' box to set mapred.system.dir.",
              order: 2
          }

attribute 'swift_block_size',
          description: 'fs.swift.blocksize',
          required: 'required',
          default: '131072',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 3
          }

attribute 'swift_request_size',
          description: 'fs.swift.requestsize',
          required: 'required',
          default: '1024',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 4
          }

attribute 'swift_connect_timeout',
          description: 'fs.swift.connect.timeout',
          required: 'required',
          default: '30000',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 5
          }

attribute 'swift_socket_timeout',
          description: 'fs.swift.socket.timeout',
          required: 'required',
          default: '300000',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 6
          }

attribute 'swift_connect_retry_count',
          description: 'fs.swift.connect.retry.count',
          required: 'required',
          default: '3',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 7
          }

attribute 'swift_throttle_delay',
          description: 'fs.swift.connect.throttle.delay',
          required: 'required',
          default: '0',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 8
          }

attribute 'swift_lazyseek',
          description: 'fs.swift.lazyseek',
          default: 'true',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 9,
              form: { 'field' => 'checkbox' }
          }

attribute 'swift_default_region_name',
          description: 'Default region name for writes',
          required: 'required',
          default: 'swift_default_region_name',
          format: {
              category: '5.Swift Properties',
              filter: { 'all' => { 'visible' => 'show_swift_properties:eq:true' } },
              order: 10
          }

#         _____
#     ___|___ /
#    / __| |_ \
#    \__ \___) |
#    |___/____/
#    s3

attribute 'show_s3_properties',
          description: 'Show S3 properties',
          default: 'false',
          format: {
              category: '6.S3 Properties',
              filter: { 'all' => { 'visible' => 'hive_config_only:eq:false' } },
              help: 'Check this box only if you want to view or change the default S3 properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 's3a_access_key',
          description: 'fs.s3a.access.key',
          encrypted: true,
          default: 'put_your_aws_access_key_here',
          format: {
              category: '6.S3 Properties',
              filter: { 'all' => { 'visible' => 'show_s3_properties:eq:true' } },
              order: 2
          }

attribute 's3a_secret_key',
          description: 'fs.s3a.secret.key',
          encrypted: true,
          default: 'somepassword',
          format: {
              category: '6.S3 Properties',
              filter: { 'all' => { 'visible' => 'show_s3_properties:eq:true' } },
              order: 3
          }

attribute 's3a_end_point',
          description: 'fs.s3a.endpoint',
          default: 's3a_endpoint_url',
          format: {
              category: '6.S3 Properties',
              filter: { 'all' => { 'visible' => 'show_s3_properties:eq:true' } },
              order: 4
          }

#     _     _
#    | |__ (_)_   _____
#    | '_ \| \ \ / / _ \
#    | | | | |\ V /  __/
#    |_| |_|_| \_/ \___|
#    hive

attribute 'show_hive_properties',
          description: 'Show Hive properties',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              help: 'Check this box only if you want to view or change the default Hive properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'hive_install_dir',
          description: 'Hive Installation Directory',
          required: 'required',
          default: '/opt',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Base directory of where Hive will be installed',
              order: 2
          }

attribute 'hive_tarball_url',
          description: 'Hive tarball to be used to install hive',
          required: 'required',
          default: 'hive_tarball_url',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'URL to be used to grab tarball.',
              order: 4
          }

attribute 'force_hive_reinstall',
          description: 'Download and re-install hive regardless of if the version of the tarball specified above is already installed',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Typically on a re-deployment, hive will only be re-installed on an upgrade, this option forces a re-deployment',
              order: 5,
              form: { 'field' => 'checkbox' }
          }

attribute 'hive_user',
          description: 'Username to run as',
          required: 'required',
          default: 'hive',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'The username the services will run as',
              order: 6
          }

attribute 'hive_connect_url',
          description: 'JDBC Connection',
          required: 'required',
          default: 'hive_connect_url',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'JDBC connect string for a JDBC metastore',
              order: 7
          }

attribute 'hive_db_name',
          description: 'User Name',
          required: 'required',
          default: 'meta_store_app',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Username to use against metastore database',
              order: 8
          }

attribute 'hive_db_password',
          description: 'User Password',
          required: 'required',
          encrypted: 'true',
          default: 'somepassword',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Password to use against metastore database',
              order: 9
          }

attribute 'hive_standalone_namenode',
          description: 'Resource manager and namenode override for standalone client',
          required: 'required',
          default: 'some_hostname_or_ip',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Resource manager and namenode override for standalone client.  Any detected resource manager and namenode will be ignored and the specified value will be used instead.',
              order: 10
          }

attribute 'extra_hive_site',
          description: 'Custom hive-site.xml properties',
          data_type: 'text',
          default: '',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'Extra properties to be added to hive-site.xml',
              order: 11
          }

attribute 'enable_thrift_metastore',
          description: 'Enable Thrift Metastore Service',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'This will enable the thrift metastore service on the client',
              order: 12,
              form: { 'field' => 'checkbox' }
          }

attribute 'enable_hiveserver2',
          description: 'Enable Hiveserver2',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'This will generate a keystore and truststore and enable hiveserver2 ssl support in hive-site.xml',
              order: 13,
              form: { 'field' => 'checkbox' }
          }

attribute 'hive_server2_thrift_port',
          description: "Port number of HiveServer2 thrift interface wen hive.server2.transport.mode is 'binary'",
          default: '10000',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'use_hive_thrift_url:eq:true' } },
              help: "Port number of HiveServer2 thrift interface wen hive.server2.transport.mode is 'binary'",
              order: 14
          }

attribute 'use_hive_thrift_url',
          description: 'Use Hive Thrift URL Override',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'If a URL is specified below, this will disable the MySQL connection and use the Thrift URL provided for the metastore.',
              order: 15,
              form: { 'field' => 'checkbox' }
          }

attribute 'hive_thrift_url',
          description: 'Hive Thrift URL',
          default: '',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'use_hive_thrift_url:eq:true' } },
              help: 'This will use the specified Thrift URL instead of MySQL for the metastore.  If any value is specified in this field, all other metastore connect information specified above will not be used.',
              order: 16
          }

attribute 'enable_ldap_auth',
          description: 'Use LDAP authentication for hiveserver2',
          default: 'false',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'This will enabled LDAP based authentication for hive.  Fill out details below',
              order: 17,
              form: { 'field' => 'checkbox' }
          }

attribute 'hive_server2_auth_ldap_url',
          description: 'hive.server2.authentication.ldap.url',
          default: '',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'enable_ldap_auth:eq:true' } },
              help: 'LDAP URL (for example, ldap://hostname.com:389).',
              order: 18
          }

attribute 'hive_server2_auth_ldap_domain',
          description: 'hive.server2.authentication.ldap.Domain',
          default: '',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'enable_ldap_auth:eq:true' } },
              help: 'LDAP domain. (Hive 0.12.0 and later.)',
              order: 19
          }

attribute 'hive_server2_auth_ldap_basedn',
          description: 'hive.server2.authentication.ldap.baseDN',
          default: '',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'enable_ldap_auth:eq:true' } },
              help: 'LDAP base DN. (Optional for AD.)',
              order: 20
          }

attribute 'hive_startup_hql_scripts',
          description: 'URL locations of Scripts to be run when initializing a new hive session',
          data_type: 'array',
          default: '[]',
          format: {
              category: '7.Hive Properties',
              filter: { 'all' => { 'visible' => 'show_hive_properties:eq:true' } },
              help: 'The specified URLs of scripts will be downloaded and installed in the $HIVE_HOME/conf/startup-hql directory',
              order: 21
          }

#           _
#     _ __ (_) __ _
#    | '_ \| |/ _` |
#    | |_) | | (_| |
#    | .__/|_|\__, |
#    |_|      |___/
#    pig

attribute 'enable_pig',
          description: 'Enable Pig And Show Pig Properties',
          default: 'false',
          format: {
              category: '8.Pig Properties',
              help: 'Check this box only if you want to enable Pig and view or change the default Pig properties',
              order: 1,
              form: { 'field' => 'checkbox' }
          }

attribute 'pig_install_dir',
          description: 'Pig Installation Directory',
          required: 'required',
          default: '/opt',
          format: {
              category: '8.Pig Properties',
              filter: { 'all' => { 'visible' => 'enable_pig:eq:true' } },
              help: 'Base directory of where Pig will be installed',
              order: 2
          }

attribute 'pig_tarball_url',
          description: 'Pig tarball to be used to install pig',
          required: 'required',
          default: 'pig_tarball',
          format: {
              category: '8.Pig Properties',
              filter: { 'all' => { 'visible' => 'enable_pig:eq:true' } },
              help: 'URL to be used to grab tarball.',
              order: 3
          }

attribute 'force_pig_reinstall',
          description: 'Download and re-install pig regardless of if the version of the tarball specified above is already installed',
          default: 'false',
          format: {
              category: '8.Pig Properties',
              filter: { 'all' => { 'visible' => 'enable_pig:eq:true' } },
              help: 'Typically on a re-deployment, pig will only be re-installed on an upgrade, this option forces a re-deployment',
              order: 4,
              form: { 'field' => 'checkbox' }
          }

attribute 'pig_user',
          description: 'Username to run as',
          required: 'required',
          default: 'pig',
          format: {
              category: '8.Pig Properties',
              filter: { 'all' => { 'visible' => 'enable_pig:eq:true' } },
              help: 'The username the services will run as',
              order: 5
          }
