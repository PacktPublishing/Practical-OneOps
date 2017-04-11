include_pack 'docker'

name         'kubernetes'
description  'Kubernetes'
type         'Platform'
category     'Infrastructure Service'

variable 'docker-root-master',
         :description => 'Root of the Docker runtime.',
         :value => '/var/lib/docker'

variable 'data-volume-master',
         :description => 'Data volume for persistent or shared data.',
         :value => '/data'


resource 'secgroup',
  :attributes => {
      :inbound => '[
        "22 22 tcp 0.0.0.0/0", 
        "1 65535 tcp 0.0.0.0/0",
        "1 65535 udp 0.0.0.0/0"
      ]'
  }

resource 'docker_engine',
         :attributes => {
             :version => '1.12.6',
             :root => '$OO_LOCAL{docker-root}',
             :repo => '$OO_LOCAL{docker-repo}',
             :network => 'flannel',
             :network_cidr => '11.11.0.0/16'
         } 
 
resource 'secgroup-master',
  :cookbook => 'oneops.1.secgroup',
  :design => true,
  :attributes => {
      :inbound => '["22 22 tcp 0.0.0.0/0", 
                    "1 65535 tcp 0.0.0.0/0",
                    "1 65535 udp 0.0.0.0/0"    
      ]'
  },
  :requires => {
      :constraint => '1..1',
      :services => 'compute'
  }
  
resource 'compute-master',
  :cookbook => "oneops.1.compute",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns" },
  :attributes => { "size"    => "S"
                 },
  :monitors => {
      'ssh' =>  { :description => 'SSH Port',
                  :chart => {'min'=>0},
                  :cmd => 'check_port',
                  :cmd_line => '/opt/nagios/libexec/check_port.sh',
                  :heartbeat => true,
                  :duration => 5,
                  :metrics =>  {
                    'up'  => metric( :unit => '%', :description => 'Up %')
                  },
                  :thresholds => {
                  },
                }
  },
  :payloads => {
    'os' => {
      'description' => 'os',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Compute",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Os"
           }
         ]
      }'
    }
  }

resource 'os',
  :attributes => {
    :ostype => 'centos-7.2',
    :sysctl => '{"net.core.somaxconn":"2048","net.ipv6.conf.all.forwarding":"1"}'      
  }
    
resource 'os-master',
  :cookbook => 'oneops.1.os',
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
  :attributes => { "ostype"   => "centos-7.2",
                   "dhclient" => 'true',
                   'sysctl' => '{"net.core.somaxconn":"2048","net.ipv6.conf.all.forwarding":"1"}'                       
                 },
:monitors => {
    'cpu' =>  { :description => 'CPU',
                :source => '',
                :chart => {'min'=>0,'max'=>100,'unit'=>'Percent'},
                :cmd => 'check_local_cpu!10!5',
                :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
                :metrics =>  {
                  'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                  'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                  'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                  'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                  'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                  'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
                },
                :thresholds => {
                   'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                   'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
                }
              },
    'load' =>  { :description => 'Load',
                :chart => {'min'=>0},
                :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
                :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
                :duration => 5,
                :metrics =>  {
                  'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                  'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                  'load15' => metric( :unit => '', :description => 'Load 15min Average'),
                },
                :thresholds => {
                },
              },
    'disk' =>  {'description' => 'Disk',
                'chart' => {'min'=>0,'unit'=> '%'},
                'cmd' => 'check_disk_use!/',
                'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                               'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                :thresholds => {
                  'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                },
              },
    'mem' =>  { 'description' => 'Memory',
                'chart' => {'min'=>0,'unit'=>'KB'},
                'cmd' => 'check_local_mem!90!95',
                'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
                'metrics' =>  {
                  'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                  'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                  'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                  'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
                },
                :thresholds => {
                },
            },
    'network' => {:description => 'Network',
                     :source => '',
                     :chart => {'min' => 0, 'unit' => ''},
                     :cmd => 'check_network_bandwidth',
                     :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
                     :metrics => {
                       'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                       'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
                }
           }
  },
  :payloads => {
  'linksto' => {
    'description' => 'LinksTo',
    'definition' => '{
      "returnObject": false,
      "returnRelation": false,
      "relationName": "base.RealizedAs",
      "direction": "to",
      "relations": [
        { "returnObject": false,
          "returnRelation": false,
          "relationName": "manifest.Requires",
          "direction": "to",
          "targetClassName": "manifest.Platform",
          "relations": [
            { "returnObject": false,
              "returnRelation": false,
              "relationName": "manifest.LinksTo",
              "direction": "from",
              "targetClassName": "manifest.Platform",
              "relations": [
                { "returnObject": true,
                  "returnRelation": false,
                  "relationName": "manifest.Entrypoint",
                  "direction": "from"
                }
              ]
            }
          ]
        }
      ]
    }'
  }
}    


resource 'etcd-master',
  :cookbook => 'oneops.1.etcd',
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :design => true,
  :payloads => {
'RequiresComputes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Etcd",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "from",
           "targetClassName": "manifest.oneops.1.Compute",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Compute"
             }
           ]
         }
       ]
    }'
  }
 }

 
# docker volume on master optional to not impact existing envs 
# new envs should enable this to minimize root filesystem contention
resource 'volume-docker-master',
  :cookbook => 'oneops.1.volume',
  :design => true,
  :requires => {:constraint => '0..1', :services => 'compute'},
  :attributes => {:mount_point => '/var/lib/docker',
                  :size => '50%FREE',
                  :fstype => 'xfs'
  },
  :monitors => {
      :usage => {:description => 'Usage',
                 :chart => {:min => 0, :unit => 'Percent used'},
                 :cmd => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                 :cmd_line => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                 :metrics => {:space_used => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                              :inode_used => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                 :thresholds => {
                     :LowDiskSpaceCritical => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                     :LowDiskInodeCritical => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                 }
      }
  }
   
# optional block storage for docker on master 
# if enabled change the 50%FREE in volume-docker-master in design to 100%FREE
resource "storage-docker-master",
  :cookbook => "oneops.1.storage",
  :design => true,
  :attributes => {
    "size"        => '40G',
    "slice_count" => '1'
  },
  :requires => { "constraint" => "0..1", "services" => "storage" },
  :payloads => {
    'volumes' => {
     'description' => 'volumes',
     'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Storage",
       "relations": [
         { "returnObject": true,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Volume"
         }
       ]
     }'
   }
  }   
  
resource 'volume-etcd',
         :cookbook => 'oneops.1.volume',
         :design => true,
         :requires => {:constraint => '1..1', :services => 'compute'},
         :attributes => {:mount_point => '/etcd',
                         :size => '100%FREE',
                         :fstype => 'xfs'
         },
         :monitors => {
             :usage => {:description => 'Usage',
                        :chart => {:min => 0, :unit => 'Percent used'},
                        :cmd => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                        :cmd_line => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                        :metrics => {:space_used => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                     :inode_used => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                        :thresholds => {
                            :LowDiskSpaceCritical => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                            :LowDiskInodeCritical => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                        }
             }
         }         
           
resource 'kubernetes-master',
  :cookbook => 'oneops.1.kubernetes',
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :design => true,
  :payloads => {
  'master-computes' => {
    'description' => 'master-computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Kubernetes",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "targetCiName": "kubernetes-master",
               "direction": "from",
               "targetClassName": "manifest.oneops.1.Kubernetes",
              "relations": [
                { "returnObject": false,
                  "returnRelation": false,
                  "relationName": "manifest.ManagedVia",
                  "direction": "from",
                  "targetClassName": "manifest.oneops.1.Compute",
                  "relations": [
                      { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.RealizedAs",
                        "direction": "from",
                        "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
  
                 }              
               ]
  
             }
           ]
         }
       ]
    }'
  },
    'node-computes' => {
      'description' => 'computes',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Kubernetes",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "targetCiName": "kubernetes-node",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Kubernetes",
                "relations": [
                  { "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.oneops.1.Compute",
                    "relations": [
                        { "returnObject": true,
                          "returnRelation": false,
                          "relationName": "base.RealizedAs",
                          "direction": "from",
                          "targetClassName": "bom.oneops.1.Compute"
                        }
                      ]
    
                   }              
                 ]
    
               }
             ]
           }
         ]
      }'
    },
    'manifest-docker' => {
      'description' => 'manifest-docker',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Kubernetes",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": true,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Docker_engine"    
               }
             ]
           }
         ]
      }'
    },
    'lbmaster' => {
      'description' => 'lb',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Kubernetes",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Lb",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "base.RealizedAs",
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Lb"    
                   }
                 ]      
               }
             ]
           }
         ]
      }'
    }           
  },
:monitors => {
    'nodes' =>  { :description => 'Nodes',
                :source => '',
                :cmd => 'check_nodes',
                :cmd_line => '/opt/nagios/libexec/check_nodes.rb',
                :metrics =>  {
                  'ready'   => metric( :unit => 'count', :description => 'Ready'),
                  'total'   => metric( :unit => 'count', :description => 'Total'),
                  'percent_ready'   => metric( :unit => '%', :description => 'Percent Ready'),                  
                },
                :thresholds => {
                  'PercentReady' => threshold('1m','avg','percent_ready',trigger('<=', 75, 1, 1), reset('>', 75, 1, 1))
                }
              },
    'pods' =>  { :description => 'Pods',
                :source => '',
                :cmd => 'check_pods',
                :cmd_line => '/opt/nagios/libexec/check_pods.rb',
                :metrics =>  {
                  'pending'   => metric( :unit => 'count', :description => 'Pending'),
                  'running'   => metric( :unit => 'count', :description => 'Running'),
                  'crash'   => metric( :unit => 'count', :description => 'CrashLoopBackOff'),                    
                  'total'   => metric( :unit => 'count', :description => 'Total'),
                  'percent_running'   => metric( :unit => '%', :description => 'Percent Running'),                  
                },
                :thresholds => {
                  'PercentRunning' => threshold('1m','avg','percent_running',trigger('<=', 75, 1, 1), reset('>', 75, 1, 1))
                }
              }
                
}

resource 'docker_engine-master',
         :cookbook => 'oneops.1.docker_engine',
         :design => true,
         :requires => {:constraint => '1..1',
                       :services => 'compute,*mirror'},
         :attributes => {
             :version => '1.11.2',
             :root => '$OO_LOCAL{docker-root-master}',
             :repo => '$OO_LOCAL{docker-repo}'
         },
         :monitors => {
             :dockerProcess => {:description => 'DockerEngine',
                                :source => '',
                                :chart => {:min => '0', :max => '100', :unit => 'Percent'},
                                :cmd => 'check_process!docker!true!docker!false',
                                :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                                :metrics => {
                                    :up => metric(:unit => '%', :description => 'Percent Up'),
                                },
                                :thresholds => {
                                    :dockerEngineDown => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                                }
             }
         },
        :payloads => {
          # etcd computes for flannel
          'etcd-computes' => {
            'description' => 'etcd-computes',
            'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Docker_engine",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.Requires",
                   "direction": "to",
                   "targetClassName": "manifest.Platform",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.Requires",
                       "targetCiName": "kubernetes-master",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Etcd",
                      "relations": [
                        { "returnObject": false,
                          "returnRelation": false,
                          "relationName": "manifest.ManagedVia",
                          "direction": "from",
                          "targetClassName": "manifest.oneops.1.Compute",
                          "relations": [
                              { "returnObject": true,
                                "returnRelation": false,
                                "relationName": "base.RealizedAs",
                                "direction": "from",
                                "targetClassName": "bom.oneops.1.Compute"
                              }
                            ]

                         }
                       ]

                     }
                   ]
                 }
               ]
            }'
          }
        }



resource 'kubernetes-node',
  :cookbook => 'oneops.1.kubernetes',
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "*mirror" },
  :payloads => {
'master-computes' => {
  'description' => 'master-computes',
  'definition' => '{
     "returnObject": false,
     "returnRelation": false,
     "relationName": "base.RealizedAs",
     "direction": "to",
     "targetClassName": "manifest.oneops.1.Kubernetes",
     "relations": [
       { "returnObject": false,
         "returnRelation": false,
         "relationName": "manifest.Requires",
         "direction": "to",
         "targetClassName": "manifest.Platform",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "targetCiName": "kubernetes-master",
             "direction": "from",
             "targetClassName": "manifest.oneops.1.Kubernetes",
            "relations": [
              { "returnObject": false,
                "returnRelation": false,
                "relationName": "manifest.ManagedVia",
                "direction": "from",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [
                    { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.RealizedAs",
                      "direction": "from",
                      "targetClassName": "bom.oneops.1.Compute"
                    }
                  ]

               }              
             ]

           }
         ]
       }
     ]
  }'
},
  'node-computes' => {
    'description' => 'computes',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Kubernetes",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "targetCiName": "kubernetes-node",
               "direction": "from",
               "targetClassName": "manifest.oneops.1.Kubernetes",
              "relations": [
                { "returnObject": false,
                  "returnRelation": false,
                  "relationName": "manifest.DependsOn",
                  "direction": "from",
                  "targetClassName": "manifest.oneops.1.Compute",
                  "relations": [
                      { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.RealizedAs",
                        "direction": "from",
                        "targetClassName": "bom.oneops.1.Compute"
                      }
                    ]
  
                 }              
               ]
  
             }
           ]
         }
       ]
    }'
  }  
}

resource "lb",
  :attributes => {
    "listeners"     => '["tcp 80 tcp 31111"]',
    "ecv_map"       => '{"31111":"port-check"}'
  }
  
resource "lb-master-certificate",
  :cookbook => "oneops.1.certificate",
  :design => true,
  :requires => { "constraint" => "0..1" },
  :attributes => {}

resource "lb-master",
  :except => [ 'single' ],
  :design => true,
  :cookbook => "oneops.1.lb",
  :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
  :attributes => {
    "listeners"     => '["http 8080 http 8080"]',
    "ecv_map"       => '{"8080":"GET /api/"}'
  },
  :payloads => {
  'primaryactiveclouds' => {
      'description' => 'primaryactiveclouds',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.Lb",
         "relations": [
           { "returnObject": false,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "to",
             "targetClassName": "manifest.Platform",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                  {"attributeName":"adminstatus", "condition":"neq", "avalue":"offline"}],
                 "relationName": "base.Consumes",
                 "direction": "from",
                 "targetClassName": "account.Cloud",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"lb"}],
                     "relationName": "base.Provides",
                     "direction": "from",
                     "targetClassName": "cloud.service.Netscaler"
                   }
                 ]
               }
             ]
           }
         ]
      }'
    }
  }

resource "fqdn-master",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*gdns,lb" },
  :attributes => { "aliases" => '["master"]' },
  :payloads => {
'environment' => {
    'description' => 'Environment',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment"
             }
           ]
         }
       ]
    }'
  },
'activeclouds' => {
    'description' => 'activeclouds',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
               "relationName": "base.Consumes",
               "direction": "from",
               "targetClassName": "account.Cloud",
               "relations": [
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.Netscaler"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Route53"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Designate"
                 },
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationName": "base.Provides",
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                 },    
                 { "returnObject": true,
                   "returnRelation": false,
                   "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                   "relationName": "base.Provides",
                   "direction": "from",
                   "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
'organization' => {
    'description' => 'Organization',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Fqdn",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "manifest.Requires",
           "direction": "to",
           "targetClassName": "manifest.Platform",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.ComposedOf",
               "direction": "to",
               "targetClassName": "manifest.Environment",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedIn",
                   "direction": "to",
                   "targetClassName": "account.Assembly",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Manages",
                       "direction": "to",
                       "targetClassName": "account.Organization"
                     }
                   ]
                 }
               ]
             }
           ]
         }
       ]
    }'
  },
 'lb' => {
    'description' => 'all loadbalancers',
    'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "bom.DependsOn",
       "direction": "from",
       "targetClassName": "bom.oneops.1.Lb",
       "relations": [
         { "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Lb",
           "relations": [
             { "returnObject": true,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "from",
               "targetClassName": "bom.oneops.1.Lb"
             }
           ]
         }
       ]
    }'
  },
   'remotedns' => {
       'description' => 'Other clouds dns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Infoblox"
                     },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Route53"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Designate"
                    },
                   { "returnObject": true,
                      "returnRelation": false,
                      "relationName": "base.Provides",
                      "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                      "direction": "from",
                      "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                    },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"dns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Infoblox"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    },
   'remotegdns' => {
       'description' => 'Other clouds gdns services',
       'definition' => '{
           "returnObject": false,
           "returnRelation": false,
           "relationName": "base.RealizedAs",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Fqdn",
           "relations": [
             { "returnObject": false,
               "returnRelation": false,
               "relationName": "manifest.Requires",
               "direction": "to",
               "targetClassName": "manifest.Platform",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.Consumes",
                   "direction": "from",
                   "targetClassName": "account.Cloud",
                   "relations": [
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Netscaler"
                     },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.Netscaler"
                     },       
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Route53"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Designate"
                      },
                     { "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.Provides",
                        "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                        "direction": "from",
                        "targetClassName": "cloud.service.oneops.1.Rackspacedns"
                      },
                     { "returnObject": true,
                       "returnRelation": false,
                       "relationName": "base.Provides",
                       "relationAttrs":[{"attributeName":"service", "condition":"eq", "avalue":"gdns"}],
                       "direction": "from",
                       "targetClassName": "cloud.service.oneops.1.Azuretrafficmanager"
                     }
                   ]
                 }
               ]
             }
           ]
      }'
    }
  }
  
  
resource 'user-master',
  :cookbook => "oneops.1.user",
  :design => true,
  :requires => { "constraint" => "0..*" }

resource 'system-container-apps',
  :cookbook => "oneops.1.container-app",
  :design => true,
  :requires => { "constraint" => "0..*" }

# for clean nodes list
resource 'hostname',
  :requires => { "constraint" => "1..1", "services" => "dns" }


resource 'daemon-apiserver',
  :cookbook => "oneops.1.daemon",
  :design => true,
  :attributes => {
      :service_name => 'kube-apiserver',
      :use_script_status => 'true'
  },
  :requires => { "constraint" => "1..1" },
  :monitors => {
      'process' =>  { :description => 'Process',
                  :source => '',
                  :chart => {'min'=>'0','max'=>'100','unit'=>'Percent'},
                  :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!true!null!false',
                  :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                  :metrics =>  {
                    'up'   => metric( :unit => '%', :description => 'Percent Up'),
                  },
                  :thresholds => {  
                     'ProcessDown' => threshold('1m','avg','up',trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                  }
                }
  }

resource 'daemon-controller-manager',
  :cookbook => "oneops.1.daemon",
  :design => true,
  :attributes => {
      :service_name => 'kube-controller-manager',
      :use_script_status => 'true'
  },
  :requires => { "constraint" => "1..1" },
  :monitors => {
      'process' =>  { :description => 'Process',
                  :source => '',
                  :chart => {'min'=>'0','max'=>'100','unit'=>'Percent'},
                  :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!true!null!false',
                  :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                  :metrics =>  {
                    'up'   => metric( :unit => '%', :description => 'Percent Up'),
                  },
                  :thresholds => {  
                     'ProcessDown' => threshold('1m','avg','up',trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                  }
                }
  }

resource 'daemon-scheduler',
  :cookbook => "oneops.1.daemon",
  :design => true,
  :attributes => {
      :service_name => 'kube-scheduler',
      :use_script_status => 'true'
  },
  :requires => { "constraint" => "1..1" },
  :monitors => {
      'process' =>  { :description => 'Process',
                  :source => '',
                  :chart => {'min'=>'0','max'=>'100','unit'=>'Percent'},
                  :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!true!null!false',
                  :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                  :metrics =>  {
                    'up'   => metric( :unit => '%', :description => 'Percent Up'),
                  },
                  :thresholds => {  
                     'ProcessDown' => threshold('1m','avg','up',trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                  }
                }
  }
        
resource 'daemon-kubelet',
  :cookbook => "oneops.1.daemon",
  :design => true,
  :attributes => {
      :service_name => 'kubelet',
      :use_script_status => 'true'
  },
  :requires => { "constraint" => "1..1" },
  :monitors => {
      'process' =>  { :description => 'Process',
                  :source => '',
                  :chart => {'min'=>'0','max'=>'100','unit'=>'Percent'},
                  :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!true!null!false',
                  :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                  :metrics =>  {
                    'up'   => metric( :unit => '%', :description => 'Percent Up'),
                  },
                  :thresholds => {  
                     'ProcessDown' => threshold('1m','avg','up',trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                  }
                }
  }

resource 'daemon-proxy',
  :cookbook => "oneops.1.daemon",
  :design => true,
  :attributes => {
      :service_name => 'kube-proxy',
      :use_script_status => 'true'
  },  
  :requires => { "constraint" => "1..1" },
  :monitors => {
      'process' =>  { :description => 'Process',
                  :source => '',
                  :chart => {'min'=>'0','max'=>'100','unit'=>'Percent'},
                  :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!true!null!false',
                  :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                  :metrics =>  {
                    'up'   => metric( :unit => '%', :description => 'Percent Up'),
                  },
                  :thresholds => {  
                     'ProcessDown' => threshold('1m','avg','up',trigger('<=', 98, 1, 1), reset('>', 95, 1, 1), 'unhealthy')
                  }
                }
  }
  
  
resource "job-docker-cleanup",
  :cookbook => "oneops.1.job",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
        :minute => "7",
        :cmd => "/opt/oneops/docker-cleanup.sh"
  }
  
resource "job-docker-cleanup-master",
  :cookbook => "oneops.1.job",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
        :minute => "7",
        :cmd => "/opt/oneops/docker-cleanup.sh"
  }


#
# relations
#

[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::compute-master",
    :only => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>3, "min" => 1, "max" => 9}
end

# -d name due to pack sync logic uses a map keyed by that name - it doesnt get put into cms
[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::compute-d",
    :only => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "flex" => false }
end

       
[ 'lb-master' ].each do |from|
  relation "#{from}::depends_on::lb-master-certificate",
    :except => [ 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource => 'lb-certificate',
    :attributes => { "propagate_to" => 'from', "flex" => false, "min" => 0, "max" => 1 }
end


# depends_on

[ 'lb' ].each do |from|
  relation "#{from}::depends_on::compute",
    :only => [ 'redundant' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" =>2, "min" => 1, "max" => 256}
end


[ 'fqdn-master' ].each do |from|
  relation "#{from}::depends_on::lb-master",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false }
end    

# needed for kube-proxy --master arg (only takes 1 ip) and a name/domain will not work 
# more notes in the node recipe
[ 'kubernetes-node' ].each do |from|
  relation "#{from}::depends_on::lb-master",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'lb-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "converge" => true }
end

[ 'system-container-apps' ].each do |from|
  relation "#{from}::depends_on::kubernetes-node",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'kubernetes-node',
    :attributes    => { "flex" => false, "converge" => true }
end


[ 'fqdn-master' ].each do |from|
  relation "#{from}::depends_on::compute-master",
    :only => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { "propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }
end  


[ { :from => 'compute-master',     :to => 'secgroup-master' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "converge" => true, "min" => 1, "max" => 1 }
end

[ { :from => 'user-master',       :to => 'os-master' },
  { :from => 'etcd-master',       :to => 'compute-master' },
  { :from => 'etcd-master',       :to => 'os-master' },
  { :from => 'volume-etcd',       :to => 'os-master' },
  { :from => 'job-docker-cleanup-master', :to => 'docker_engine-master' },      
  { :from => 'docker_engine-master', :to => 'volume-docker-master' },    
  { :from => 'volume-etcd',       :to => 'volume-docker-master' },
  { :from => 'docker_engine-master', :to => 'compute-master' },    
  { :from => 'volume-docker-master', :to => 'compute-master' },
  { :from => 'job-docker-cleanup-master', :to => 'compute-master' },
  { :from => 'volume-docker-master', :to => 'storage-docker-master' },
  { :from => 'etcd-master',       :to => 'volume-etcd' },    
  { :from => 'kubernetes-master', :to => 'etcd-master' },
  { :from => 'os-master',         :to => 'compute-master' },
  { :from => 'daemon-controller-manager', :to => 'kubernetes-master' },
  { :from => 'daemon-apiserver',  :to => 'kubernetes-master' },
  { :from => 'daemon-scheduler',  :to => 'kubernetes-master' },
  { :from => 'daemon-kubelet',    :to => 'kubernetes-node' },
  { :from => 'daemon-proxy',      :to => 'kubernetes-node' },
  { :from => 'kubernetes-node',   :to => 'docker_engine' },
  { :from => 'job-docker-cleanup',:to => 'docker_engine' },
  { :from => 'kubernetes-node',   :to => 'compute' }
    ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { } 
end


# managed_via
[ 'os-master','etcd-master','kubernetes-master','user-master','system-container-apps',
  'daemon-controller-manager', 'daemon-apiserver', 'daemon-scheduler', 'volume-etcd', 
  'volume-docker-master', 'docker_engine-master', 'job-docker-cleanup-master'].each do |from|
  relation "#{from}::managed_via::compute-master",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute-master',
    :attributes    => { } 
end

[ 'kubernetes-node', 'daemon-kubelet', 'daemon-proxy', 'job-docker-cleanup'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { } 
end


# secured_by
[ 'compute-master'].each do |from|
  relation "#{from}::secured_by::sshkeys",
    :except => [ '_default' ],
    :relation_name => 'SecuredBy',
    :from_resource => from,
    :to_resource   => 'sshkeys',
    :attributes    => { }
end


