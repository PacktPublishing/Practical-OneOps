name              "Bucket"
description       "Installs/Configures couchbase"
version           "0.1"
maintainer        "OneOps"
maintainer_email  "support@oneops.com"
license           "Apache License, Version 2.0"


grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'adminuser',
          :description => "Admin User",
          :required => "optional",
          :default => "Administrator",
          :format => {
              :help => 'Cluster administration username',
              :category => '2.Cluster',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'adminpassword',
          :description => "Admin Password",
          :required => "optional",
          :default => "password",
          :format => {
              :help => 'Cluster administration password',
              :category => '2.Cluster',
              :order => 3,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }
# bucket
attribute 'bucketname',
          :description => "Bucket Name",
          :default => "test",
          :format => {
              :help => 'Name of the bucket to be added to the server',
              :category => '1.Bucket',
              :order => 1
          }
          
attribute 'bucketpassword',
          :description => "Bucket password",
          :required => "required",
          :encrypted => true,
          :default => "password",
          :format => {
              :help => 'Bucket password for authentication.',
              :category => '1.Bucket',
              :order => 2
          }



attribute 'bucketmemory',
          :description => "Per Node RAM Quota in MB",
          :default => "256",
          :format => {
              :help => 'Bucket Size: Per Node RAM Quota in MB',
              :category => '1.Bucket',
              :order => 3
          }

attribute 'bucketreplica',
          :description => "No. of Replicas",
          :required => "optional",
          :default => "1",
          :format => {
              :help => ' The no of data copies on the cluster',
              :category => '1.Bucket',
              :order => 4,
              :form => {'field' => 'select', 'options_for_select' => [['1', '1'], ['2', '2'], ['3', '3']]}
          }

attribute 'bucketport',
          :description => "Bucket Port",
          :default => "11211",
          :format => {
              :help => 'Port for the default bucket. The default bucket is a Couchbase bucket that always resides on port 11211.',
              :category => '1.Bucket',
              :order => 5,
              :editable => false
          }


