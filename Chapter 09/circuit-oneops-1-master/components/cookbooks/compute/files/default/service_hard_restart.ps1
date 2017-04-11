Param( 
[string] $processName,
[string] $serviceName
)

#Try to kill service process
if ($serviceName) { Get-WmiObject -Class Win32_Service -Filter "Name LIKE '$($serviceName)%'"| ForEach-Object {taskkill.exe /PID $_.ProcessId /T /F} }

#Kill orphaned processes
if ($processName) 
{ 

    $a = Get-WmiObject -Class Win32_Process -Filter "Name LIKE '$($processName)%'"

    foreach ($b in $a) 
    { 
    	if (!(Get-Process -Id $b.ParentProcessId -ErrorAction Ignore) ) 
    	{ 
    		taskkill.exe /PID $b.ProcessId /T /F
    		break 
    	}
    }
}

#wait 5 sec and restart the service
Start-Sleep -s 5

(Get-Service $serviceName).Start()