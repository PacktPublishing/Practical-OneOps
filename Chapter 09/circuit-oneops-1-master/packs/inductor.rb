include_pack  "base"
name          "inductor"
description   "Inductor"
type          "Platform"
category      "Other"

variable "oneops-dist",
         :description => 'OneOps Distribution Base URL',
         :value => 'http://changeme.com:3001/job/package/ws/'

variable "oneops-version",
         :description => 'OneOps Version',
         :value => 'continuous'

variable "inductor-dir",
         :description => 'Inductor installation directory path',
         :value => '/opt/oneops'

variable "inductor-version",
         :description => 'Inductor Version',
         :value => '1.0.2'

resource "secgroup",
  :cookbook => "oneops.1.secgroup",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "compute"
  },
  :attributes => {
      :inbound => '["22 22 tcp 0.0.0.0/0"]'
  }


resource "library",
  :cookbook => "oneops.1.library",
  :design => true,
  :requires => { "constraint" => "1..1" },
  :attributes => {
    "packages"  => '["lsof"]'
  }

resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '$OO_LOCAL{inductor-dir}',
                    "device"        => '',
                    "fstype"        => 'xfs',
                    "options"       => ''
                 }

resource "ruby",
  :cookbook => "oneops.1.ruby",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "*mirror"
  },
  :attributes => {
    "gems" => '{"bundler":""}'
  }

# inductor gem artifact
configure = <<-EOC
execute "gem install $OO_LOCAL{inductor-dir}/artifact/releases/$OO_LOCAL{oneops-version}/oneops/dist/inductor-$OO_LOCAL{inductor-version}.gem --no-ri --no-rdoc"
# needed for nagios to run lsof to make sure there are established connections
execute "chmod +s /usr/sbin/lsof"
EOC

restart = <<-EOR
execute "inductor create" do
  cwd "$OO_LOCAL{inductor-dir}"
end

file "/etc/profile.d/inductor.sh" do
  content "INDUCTOR_HOME=$OO_LOCAL{inductor-dir}/inductor"
end

file "/opt/oneops/inductor_env.sh" do
  content "INDUCTOR_HOME=$OO_LOCAL{inductor-dir}/inductor"
end

execute "inductor install_initd" do
  cwd "$OO_LOCAL{inductor-dir}/inductor"
end
EOR

resource "inductor-gem",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => {
     :constraint => "0..1",
     :services => "*maven"
  },
  :attributes => {
     :url => '$OO_LOCAL{oneops-dist}/oneops-$OO_LOCAL{oneops-version}.tar.gz',
     :repository => 'oneops_releases',
     :username => '',
     :password => '',
     :location => '$OO_LOCAL{oneops-dist}/oneops-$OO_LOCAL{oneops-version}.tar.gz',
     :version => '$OO_LOCAL{oneops-version}',
     :checksum => '',
     :install_dir => '$OO_LOCAL{inductor-dir}/artifact',
     :as_user => 'root',
     :as_group => 'root',
     :environment => '{}',
     :persist => '[]',
     :should_expand => 'true',
     :configure => configure,
     :migrate => '',
     :restart => restart
  }
  
resource "oneops-admin-gem",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => {
     :constraint => "1..1",
     :services => "*maven"
  },
  :attributes => {
     :url => '$OO_LOCAL{oneops-dist}/oneops-$OO_LOCAL{oneops-version}.tar.gz',
     :repository => 'oneops_releases',
     :username => '',
     :password => '',
     :location => '$OO_LOCAL{oneops-dist}/oneops-$OO_LOCAL{oneops-version}.tar.gz',
     :version => '$OO_LOCAL{oneops-admin-version}',
     :checksum => '',
     :install_dir => '$OO_LOCAL{inductor-dir}/oneops-admin-artifact',
     :as_user => 'root',
     :as_group => 'root',
     :should_expand => 'true'
  }  

resource "circuit",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => {
     :constraint => "0..*",
     :services => "*maven"
  }  

resource "java",
  :cookbook => "oneops.1.java",
  :design => true,
  :requires => {
    :constraint => "0..1",
    :services => "*mirror"
  } 
  
resource "daemon",
  :cookbook => "oneops.1.daemon",
  :design => true,
  :requires => {
     :constraint => "1..1",
     :help => "Inductor"
  },
  :attributes => {
     :service_name => 'inductor',
     :use_script_status => 'true',
     :pattern => ''
  }

resource "inductor",
  :cookbook => "oneops.1.inductor",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {
    "url" => 'https://oneops.prod.changeme.com',
    "mqhost" => 'oneops.prod.changeme.com',
    "queue" => '/organization/_clouds/mycloud',
    "authkey" => 'mysecretauthkey',
    "inductor_home" => '$OO_LOCAL{inductor-dir}/inductor',
  }

# depends_on
[ { :from => 'inductor',           :to => 'inductor-gem'  },
  { :from => 'inductor',           :to => 'oneops-admin-gem'  },
  { :from => 'circuit',            :to => 'oneops-admin-gem'  },
  { :from => 'java',               :to => 'os' },
  { :from => 'ruby',               :to => 'os' },
  { :from => 'inductor-gem', :to => 'ruby' },
  { :from => 'inductor-gem', :to => 'java' },
  { :from => 'inductor-gem', :to => 'library' },
  { :from => 'inductor-gem', :to => 'volume' },
  { :from => 'oneops-admin-gem', :to => 'ruby' },
   { :from => 'oneops-admin-gem', :to => 'java' },
   { :from => 'oneops-admin-gem', :to => 'library' },
   { :from => 'oneops-admin-gem', :to => 'volume' },  
  { :from => 'ruby',              :to => 'compute' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ { :from => 'daemon', :to => 'inductor'  },
  { :from => 'daemon', :to => 'inductor-gem' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => true, "min" => 2, "max" => 10 }


# managed_via
[ 'ruby', 'oneops-admin-gem', 'inductor-gem', 'inductor', 'circuit', 'java' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
