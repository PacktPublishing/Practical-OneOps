param(
	[parameter(Mandatory=$true)]
	[string]$ExeFile,
	[parameter(Mandatory=$false)]
	[string]$ArgList,
	[parameter(Mandatory=$false)]
	[int]$Timeout
	
) 
$ErrorActionPreference = 'Stop'

if (!$Timeout) {$Timeou = 1500} #set default timeout
$taskname = 'Execute-elevated-command-' + (get-date -uformat %s)
$action = New-ScheduledTaskAction -Execute $ExeFile -Argument $ArgList

Register-ScheduledTask -Action $action -TaskName $taskname -Description "Temporary task to execute a command as LocalSystem" -User "NT AUTHORITY\SYSTEM"|Start-ScheduledTask
start-sleep 10

$duration = 0
$start = get-date -uformat %s

#wait until the task either finishes or times out
while ((schtasks.exe /query /TN "$taskname" /FO CSV | ConvertFrom-Csv | select -expandproperty Status -first 1) -ne "Ready") 
{
  $duration = (get-date -uformat %s) - $start | Out-File "/tmp/Run-Script.log" -Append
  if ($duration -gt $Timeout) 
  {
    $msg = "Stopping task ${$taskname}: Timeout has expired." 
	$msg | Out-File "/tmp/Run-Script.log" -Append
	Stop-ScheduledTask -TaskName $taskname
  }
  else 
    {start-sleep 30}
}

$TaskResult = (Get-ScheduledTask -TaskName $taskname |Get-ScheduledTaskInfo).LastTaskResult
if ($TaskResult -ne 0) 
{
  Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
  $LogFile = "C:\tmp\Execute-elevated-command.err"
  $ErrorMessage = "Error: #ERROR# `n at $ExeFile $ArgList"
  
  #Search for error file
  If (Test-Path $LogFile) 
    { $ErrorMessage = $ErrorMessage.Replace("#ERROR#",(Get-Content -Path $LogFile))}
  else 
    { $ErrorMessage = $ErrorMessage.Replace("#ERROR#","Unspecified error $TaskResult") }

  throw $ErrorMessage
}

Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
