
param(
	[parameter(Mandatory=$true)]
	[string]$searchLeter
)

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if (!$myWindowsPrincipal.IsInRole($adminRole))
   {
        # We are not running "as Administrator" - so relaunch as administrator
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition + " " + $searchLeter
        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";
        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);
        exit
   }

if (($searchLeter.length -gt 1) -or !($searchLeter -match '[e-z]')) {
    Write-Host $searchLeter "is not a valid letter for a Windows Drive"
    return 1
}

Write-Host "Trying to remove" $searchLeter "drive"

$Disk = $null
$colDiskDrives = get-wmiobject -query "Select * From Win32_DiskDrive" 
Foreach ($drive in $colDiskDrives)
{ 
    $a = $drive.DeviceID.Replace("\", "\\")
    $colPartitions = get-wmiobject -query "Associators of {Win32_DiskDrive.DeviceID=""$a""} WHERE AssocClass = Win32_DiskDriveToDiskPartition" 
    Foreach ($Partition in $colPartitions)
    {
        $b = $Partition.DeviceID 
        $colLogicalDisk = get-wmiobject -query "Associators of {Win32_DiskPartition.DeviceID=""$b""} WHERE AssocClass = Win32_LogicalDiskToPartition" 
        If ($colLogicalDisk.Caption -ne $null)
        { 
            if ($searchLeter + ":" -eq $colLogicalDisk.Caption)
            {
                $Disk = ($Partition.DeviceID -replace '\,|#','').Split(' ')[1]
                if($Disk -ne $null)
                {
                    break
                }
            }
        }
    }
    if($Disk -ne $null)
    {
        break
    }
}

if($Disk -ne $null)
{
    $volume = ("list volume" | diskpart | where {$_ -match " " + $searchLeter + " "}).Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
    $command = @"
select volume $searchLeter
delete volume
clean
select disk $Disk
offline disk
"@
    $noOut = $command | diskpart
    sleep 5
    Write-Host "Drive deleted"
    return 0
}
else
{
   Write-Host "Drive not found"
   return 1
}