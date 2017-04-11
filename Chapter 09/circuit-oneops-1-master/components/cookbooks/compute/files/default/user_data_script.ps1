#ps1_sysnative

$username = "oneops"
$cloudbase_user = "admin"

#generate a random password
[Reflection.Assembly]::LoadWithPartialName("System.Web")
$random_password = [System.Web.Security.Membership]::GeneratePassword(14,0) 
Write-host $random_password

#Add a local user
Invoke-Command -ScriptBlock {net user $username ""$random_password"" /add}

#Add the user to administrators group
Invoke-Command -ScriptBlock {net localgroup Administrators $username /add}

#Create a cygwin home directory and copy ssh keys
New-Item "C:\cygwin64\home\$username\.ssh" -ItemType Directory
Copy-Item "C:\Users\$cloudbase_user\.ssh\*" "C:\cygwin64\home\$username\.ssh\"

#Make this user an owner of home dir
Invoke-Command -ScriptBlock {icacls "C:\cygwin64\home\$username" /setowner $username /T /C} 
