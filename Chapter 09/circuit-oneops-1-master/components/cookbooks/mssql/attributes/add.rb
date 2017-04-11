#
# Cookbook:: mssql
# Attribute:: add
#
#Server settings
default['sql_server']['install_dir']    = 'C:\Program Files\Microsoft SQL Server'
default['sql_server']['instance_dir']   = 'C:\Program Files\Microsoft SQL Server'
default['sql_server']['shared_wow_dir'] = 'C:\Program Files (x86)\Microsoft SQL Server'
default['sql_server']['agent_account'] =  'NT AUTHORITY\NETWORK SERVICE'
default['sql_server']['agent_startup'] =  'Disabled'
default['sql_server']['rs_mode'] = 'FilesOnlyMode'
default['sql_server']['rs_account'] = 'NT AUTHORITY\NETWORK SERVICE'
default['sql_server']['rs_startup'] = 'Automatic'
default['sql_server']['browser_startup'] = 'Disabled'
default['sql_server']['sysadmins'] = ['Administrators']
default['sql_server']['sql_account'] = 'NT AUTHORITY\NETWORK SERVICE'
default['sql_server']['update_enabled'] = true # applies to SQL Server 2012 and later
default['sql_server']['filestream_level'] = 0
default['sql_server']['filestream_share_name'] = 'MSSQLSERVER'
default['sql_server']['server']['installer_timeout'] = 1500
default['sql_server']['server']['checksum'] = nil

version = node['mssql']['version'][6..9]
default['sql_server']['accept_eula'] = true
default['sql_server']['product_key'] = nil
default['sql_server']['server']['url'] = node['mssql']['url']
default['sql_server']['server_sa_password'] = node['mssql']['password']
default['sql_server']['version'] = version
default['sql_server']['instance_name']  = 'MSSQLSERVER'
default['sql_server']['server']['package_name'] = "Microsoft SQL Server #{version} (64-bit)"
default['sql_server']['feature_list'] = 'SQLENGINE,REPLICATION,SNAC_SDK,SSMS'
default['sql_server']['sql_temp_db_dir']   = node['mssql']['tempdb_data']
default['sql_server']['sql_temp_db_log_dir']   = node['mssql']['tempdb_log']
default['sql_server']['sql_user_db_dir']   = node['mssql']['userdb_data']
default['sql_server']['sql_user_db_log_dir']   = node['mssql']['userdb_log']


#Configure settings
# Tcp settings
default['sql_server']['tcp_enabled']       = true
default['sql_server']['port']              = 1433 # Keep port for backward compatibility
default['sql_server']['tcp_dynamic_ports'] = ''
# Named Pipes settings
default['sql_server']['np_enabled']        = false
# Shared Memory settings
default['sql_server']['sm_enabled']        = true
# Via settings
default['sql_server']['via_default_port']  = '0:1433'
default['sql_server']['via_enabled']       = false
default['sql_server']['via_listen_info']   = '0:1433'