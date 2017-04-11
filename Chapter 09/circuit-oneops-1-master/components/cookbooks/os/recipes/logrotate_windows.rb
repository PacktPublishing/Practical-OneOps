#install logrotate for windows
directory "C:/opscode/logrotate" do
  recursive true
end

#No component documentation available. Please refer to the pack documentation or [the OneOps website](http://oneops.com). - move to mirror
cookbook_file "C:/opscode/logrotate/logrotate.exe" do
  cookbook "os"
  source "logrotate.exe"
  owner "oneops"
  group "Administrators"
  mode 0770
end
  
#schedule a daily task for logrotate
ps_code = '
$action = New-ScheduledTaskAction -Execute "C:\opscode\logrotate\logrotate.exe" -Argument "/etc/logrotate.d"
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Logrotate Daily" -Description "Daily rotation of logs"  -User "System"'
  
powershell_script "Schedule logrotate daily" do
  code ps_code
  not_if "if (Get-ScheduledTask | Where-Object {$_.TaskName -like 'Logrotate Daily' }) {$true} else {$false}"
end
