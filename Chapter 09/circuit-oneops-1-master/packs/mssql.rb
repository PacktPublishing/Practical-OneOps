include_pack 'genericdb'

name 'mssql'
description 'MS SQL Server'
type 'Platform'
category 'Database Relational SQL'
ignore false

platform :attributes => {'autoreplace' => 'false'}

environment 'single', {}

variable 'temp_drive',
  :description => 'Temp Drive',
  :value       => 'T'

variable 'data_drive',
  :description => 'Data Drive',
  :value       => 'F'
  
resource 'secgroup',
         :cookbook => 'oneops.1.secgroup',
         :design => true,
         :attributes => {
             'inbound' => '[ "22 22 tcp 0.0.0.0/0", "1433 1433 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => '1..1',
             :services => 'compute'
         }


resource 'mssql',
  :cookbook => 'oneops.1.mssql',
  :design   => true,
  :requires => {
    :constraint => '1..1',
	:services   => 'mirror'
  },
  :attributes   => {
    'version' => 'mssql_2014_enterprise',
	'tempdb_data' => '$OO_LOCAL{temp_drive}:\\MSSQL',
	'tempdb_log' => '$OO_LOCAL{temp_drive}:\\MSSQL',
	'userdb_data' => '$OO_LOCAL{data_drive}:\\MSSQL\\UserData',
	'userdb_log' => '$OO_LOCAL{data_drive}:\\MSSQL\\UserLog'
  }
  
resource 'compute',
  :cookbook => 'oneops.1.compute',
  :attributes => { 'size'    => 'M-WIN' }

resource 'storage',
  :cookbook => 'oneops.1.storage',
  :requires => { 'constraint' => '1..1', 'services' => 'storage' }
  
resource 'volume',
  :cookbook => 'oneops.1.volume',
  :requires => {'constraint' => '1..1', 'services' => 'compute,storage'}, 
  :attributes => { 'mount_point'    => '$OO_LOCAL{data_drive}' }
  
resource 'vol-temp',
  :cookbook => 'oneops.1.volume',
  :requires => { 'constraint' => '1..1', 'services' => 'compute' },  
  :attributes => { 'mount_point'    => '$OO_LOCAL{temp_drive}' }
  
resource 'os',
  :cookbook => 'oneops.1.os',
  :design => true,
  :requires => { 
    :constraint => '1..1',
	:services   => 'compute,*mirror,*ntp,*windows-domain'
	},
  :attributes => {
	:ostype => 'windows_2012_r2'
  }

resource 'dotnetframework',
  :cookbook     => 'oneops.1.dotnetframework',
  :design       => true,
  :requires     => {
    :constraint => '1..1',
    :help       => 'Installs .net frameworks',
    :services   => '*mirror'
  },
  :attributes   => {
    :chocolatey_package_source   => 'https://chocolatey.org/api/v2/',
    :dotnet_version_package_name => '{ ".Net 4.6":"dotnet4.6", ".Net 3.5":"dotnet3.5" }'
  }  
  
[ 
  { :from => 'storage', :to => 'os' },
  { :from => 'vol-temp', :to => 'os' },
  { :from => 'dotnetframework', :to => 'vol-temp' },
  { :from => 'volume', :to => 'storage' }, 
  { :from => 'mssql', :to => 'volume' } ,
  { :from => 'mssql', :to => 'dotnetframework' } ,
  { :from => 'database', :to => 'mssql' } 
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { 'flex' => false, 'min' => 1, 'max' => 1 }
end

[ 'mssql', 'dotnetframework', 'os', 'volume', 'vol-temp' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
