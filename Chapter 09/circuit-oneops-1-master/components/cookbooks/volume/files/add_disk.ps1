param(
	[parameter(Mandatory=$True)]
	[string]$DriveLetter,
	[parameter(Mandatory=$false)]
	[string]$vol_id,
	[parameter(Mandatory=$false)]
	[int64]$storage_size
)
$ErrorActionPreference = "Stop"
#Logging
$Date    = Get-Date
$LogPath = "C:\tmp"
$script:LogFile = Join-Path $LogPath 'Execute-elevated-command.log'
$script:LogError  = Join-Path $LogPath 'Execute-elevated-command.err'


#Log initial details
$Admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$Whoami = whoami # Simple, could use $env as well
"Running script $($MyInvocation.MyCommand.Path) at $Date" | Out-File $script:LogFile -Append
"Admin: $Admin" | Out-File $script:LogFile -Append
"User: $Whoami" | Out-File $script:LogFile -Append
"Bound parameters: $($PSBoundParameters | Out-String)" | Out-File $script:LogFile -Append


function Output-CustomError ([string]$ErrMsg, [System.Exception]$Err)
{
  If (!$Err) {$Err = New-Object System.Exception ($ErrMsg)}

  $Err | Format-List -Force| Out-File $script:LogFile -Append
  $Err.Message | Out-File $script:LogError
  Write-Error $Err
  $ErrCode = 1
  if ($Err.HResult -gt 0) {$ErrCode = $Err.HResult}
  [System.Environment]::Exit($ErrCode)
}



#Ephemeral disk: does not depend on storage, so vol_id and storage_size are empty
#Assuming size is in gb

$GB = [math]::pow(1024,3)

#Get offline disks and switch them online
#Conditions:
#1 - nonsystem, bigger than 1GB
#2 - if vol_id is empty - Serialnumber should be empty too, else serialnumber is a substring of vol_id
#3 - storage_size is either empty, or equals Size

$disk = Get-Disk | Where-Object { $_.IsSystem -eq $False -and $_.Size -gt $GB`
  -and ( ($_.SerialNumber -and $vol_id -like "$($_.SerialNumber)*") -or (!($vol_id) -and !($_.SerialNumber) ) )`
  -and (!($storage_size) -or $storage_size*$GB -eq $_.Size) }

if (!$disk) 
{ Write-Host "About to call Output-CustomerError 1"
  #Output-CustomError "ERROR1"
  Output-CustomError -ErrMsg "The specified disk was not found. Make sure the appropriate storage is attached to the compute."
}

if ($disk.Length -gt 1) {Output-CustomError -ErrMsg "Multiple disks matched given vol_id: $vol_id"}

$DiskNum = $disk.Number

#Check if a partition with this DriveLetter already exists on another disk
If (Get-Disk | Get-Partition | Where-Object {$_.DriveLetter -eq $DriveLetter -and $_.DiskNumber -ne $DiskNum})
  {Output-CustomError -ErrMsg "The drive letter $DriveLetter is already in use"}

try 
{

  # Stops the Hardware Detection Service
  Stop-Service -Name ShellHWDetection 

  #1. Switch online
  if ((Get-Disk -Number $DiskNum).IsOffline) {Set-Disk -Number $DiskNum -IsOffline $False}

  #2. Initialize disk
  if ((Get-Disk -Number $DiskNum).PartitionStyle -eq "RAW") {Initialize-Disk -Number $DiskNum}

  #3. Create a partition
  if (!(Get-Partition -DiskNumber $DiskNum | Where-Object Type -ne "Reserved")) 
    {New-Partition -DiskNumber $DiskNum -UseMaximumSize -DriveLetter $DriveLetter}

  $Partition = Get-Partition -DiskNumber $DiskNum| Where-Object {$_.Type -ne "Reserved"}

  #4. Re-assign drive letter
  If ($Partition.DriveLetter -ne $DriveLetter) 
    {$Partition | Set-Partition -NewDriveLetter $DriveLetter}

  #5. Format the volume
  If (!(Get-Volume -DriveLetter $DriveLetter).FileSystem) {Format-Volume -DriveLetter $DriveLetter -Confirm:$false}
}
catch 
{
    Output-CustomError -Err $_.Exception
}
finally 
{  
  #Starts the Hardware Detection Service again 
  Start-Service -Name ShellHWDetection
}
