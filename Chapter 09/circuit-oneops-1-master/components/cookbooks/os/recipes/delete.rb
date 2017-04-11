#
# Cookbook Name:: os
# Recipe:: delete
#

ostype = node[:workorder][:rfcCi][:ciAttributes][:ostype]

#perform domain un-join if service exists
if ostype =~ /windows/ && node[:workorder][:services].has_key?("windows-domain") 
  Chef::Log.info("Removing Windows VM from domain")
  
  cloud_name = node[:workorder][:cloud][:ciName]
  domain = node[:workorder][:services]["windows-domain"][cloud_name][:ciAttributes]
  ps_code = "$password = '#{domain[:password]}'| ConvertTo-SecureString -asPlainText -Force
  $username = '#{domain[:domain]}\\#{domain[:username]}'
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  Remove-Computer -UnjoinDomainCredential $credential -WorkgroupName 'WORKGROUP' -Force"

  powershell_script 'unjoin-domain' do
    code ps_code
    only_if '(gwmi win32_computersystem).partofdomain'
  end
end