param(
	[parameter(Mandatory=$true)] 
	[string]$TimeZone
)
    Write-Host "TimeZone:"+$TimeZone
    $osVersion = (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("CurrentVersion") 
    $proc = New-Object System.Diagnostics.Process 
    $proc.StartInfo.WindowStyle = "Hidden" 
 
    if ($osVersion -ge 6.0) 
    { 
        # OS is newer than XP 
        $proc.StartInfo.FileName = "tzutil.exe" 
        $proc.StartInfo.Arguments = "/s `"$TimeZone`"" 
    } 
    else 
    { 
        # XP or earlier 
        $proc.StartInfo.FileName = $env:comspec 
        $proc.StartInfo.Arguments = "/c start /min control.exe TIMEDATE.CPL,,/z $TimeZone"
    } 
 
    $proc.Start() | Out-Null 
 
