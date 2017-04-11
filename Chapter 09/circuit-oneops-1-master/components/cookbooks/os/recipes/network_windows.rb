#join windows domain if service exists otherwise just change hostname
if node[:workorder][:services].has_key?("windows-domain")

  cloud_name = node[:workorder][:cloud][:ciName]
  domain = node[:workorder][:services]["windows-domain"][cloud_name][:ciAttributes]
  ps_code = "$domain = '#{domain[:domain]}'
  $password = '#{domain[:password]}'| ConvertTo-SecureString -asPlainText -Force
  $username = '#{domain[:domain]}\\#{domain[:username]}'
  $credential = New-Object System.Management.Automation.PSCredential($username,$password)
  $currentname = (Get-WmiObject -Class Win32_ComputerSystem).DNSHostName
  $newname = '#{node.vmhostname}'

  #Generate OU path
  $oupath = 'OU=Servers,'
  foreach ($a in $domain.Split('.')) { $oupath += 'DC='+$a + ',' }
  $oupath = $oupath.Substring(0,$oupath.Length-1)

  If ($currentname -ne $newname) 
  { Rename-Computer -NewName $newname -Force 
    try { Add-Computer -DomainName $domain -Credential $credential -Force -Options JoinWithNewName -ErrorAction Stop -OUPath $oupath }
    catch { Add-Computer -DomainName $domain -Credential $credential -NewName $newname -Force -ErrorAction Stop -OUPath $oupath }  }
  Else
  { Add-Computer -DomainName $domain -Credential $credential -Force -ErrorAction Stop -OUPath $oupath }  
  
  Start-Sleep -s 10"  
  
  execute 'mkpasswd-oneops' do
    command 'mkpasswd -l -u oneops > /etc/passwd'
	action :nothing
  end
  
  powershell_script 'Join-Domain' do
    code ps_code
    not_if '(gwmi win32_computersystem).partofdomain'
	notifies :run, 'execute[mkpasswd-oneops]', :before
  end
else
  #rename windows VM
  powershell_script 'Rename-Computer' do
    code "Rename-Computer -NewName '#{node[:vmhostname]}' -Force -ErrorAction Stop"
    not_if "hostname | grep #{node.vmhostname}"
  end
end


#restart
ruby_block 'declare-restart' do
  block do
    puts "***REBOOT_FLAG***"
  end
  action :nothing
  subscribes :run, 'powershell_script[Rename-Computer]', :delayed
  subscribes :run, 'powershell_script[Join-Domain]', :delayed
end
  
reboot 'perform-restart' do
  action :nothing
  subscribes :request_reboot, 'ruby_block[declare-restart]'
end
