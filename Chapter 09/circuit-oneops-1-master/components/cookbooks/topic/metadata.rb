name             "Topic"
description      "Topic"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'topicname',
          :description => 'Topic Name',
          :required => 'required',
          :format => {
              :help => 'Topic Name',
              :category => '1.Destination',
              :editable => false,
             :order => 1,
          }

attribute 'destinationtype',
          :description => 'Destination Type',
          :default => 'T',
          :format => {
              :help => 'Destination type - Topic',
              :category => '1.Destination',
              :order => 2,
              :filter => {'all' => {'visible' => 'false'}},
              :editable => false
          }

attribute 'maxmemorysize',
          :description => 'Max Memory',
          :default => '0',
          :format => {
              :help => 'Max message memory for Topic. 0 means no limit.',
              :category => '1.Destination',
              :filter => {'all' => {'visible' => 'false'}},
              :order => 3
          }

attribute 'permission',
          :description => "User Permission",
          :data_type => "hash",
          :default => '{"readonly":"R"}',
          :format => {
            :help => 'User permissions. eg (username:permission). Valid values for permissions are R for READ, W for WRITE and RW ReadWrite',
            :category => '2.Permissions',
            :pattern  => [["Read", "R"], ["Write", "W"], ["Read and Write", "RW"]] ,
            :order => 1
          }

attribute 'destinationpolicy',
          :description => "Destination Policy",
          :data_type => "text",
          :default => "",
          :format => {
            :help => 'Define destination policy specifically for this topic',
            :category => '3.Advanced',
            :order => 1
          }

attribute 'compositetopic',
          :description => "Composite Topic Definition",
          :data_type => "text",
          :default => "",
          :format => {
            :help => 'Composite Topic Definition',
            :category => '3.Advanced',
            :order => 2
          }

attribute 'virtualdestination',
          :description => "Virtual Topic Definition",
          :data_type => "text",
          :default => "",
          :format => {
            :help => 'Virtual Topic Definition',
            :category => '3.Advanced',
            :order => 3
          }

recipe 'repair', 'Repairs ActiveMQ resource'
