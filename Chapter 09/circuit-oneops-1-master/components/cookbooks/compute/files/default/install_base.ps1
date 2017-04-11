
param([string]$proxy="", [string]$chocoPkg="", [string]$chocoRepo="", [string]$gemRepo="")

function Download-File {
  param ( [string]$proxy, [string]$uri, [string]$dir, [string]$destination )

  #Create the directory if it does not exists
  New-Item -ItemType Directory -Force -Path $dir

  $start_time = Get-Date

  try {
     Invoke-WebRequest -Uri $uri -OutFile $destination
  }
  catch {
     Write-Output "Could not download from $uri "
     Write-Output "applying proxy ... "
     try {
        Invoke-WebRequest -Uri $uri -Proxy $proxy -OutFile $destination
     }
     catch {
        Write-Error "Could not download chocolatey. Cannot continue. Exiting!"
        exit 1
     }
  }
  finally {
     Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
  }
}


function Expand-ZIPFile {
  param([string]$file, [string]$destination)
  $shell = New-Object  -ComObject  Shell.Application
  $zip = $shell.NameSpace($file)

  #make sure destination exists
  #Create-DirectoryIfNotExists $destination
  New-Item -ItemType Directory -Force -Path $destination

  $shell.Namespace($destination).CopyHere($zip.Items(), 0x10)

}

## =====================================================

Write-Output "install_base param proxy: $proxy "
Write-Output "install_base param choco pkg: $chocoPkg "
Write-Output "install_base param choco repo: $chocoRepo "
Write-Output "install_base param gem repo: $gemRepo "

if( $chocoPkg -eq $null -or $chocoPkg -eq "" ) {
  $chocoPkg = "https://packages.chocolatey.org/chocolatey.0.9.9.12.nupkg"
}

$chocoTempDir = "c:\chocotemp\"
$chocoTempFile = "c:\chocotemp\choco.zip"


Write-Output "Downloading chocolatey ..."
Download-File $proxy $chocoPkg $chocoTempDir $chocoTempFile

Set-Location $chocoTempDir

Write-Output "Extracting chocolatey zipfile "
$chocoDir = Join-Path $chocoTempDir "choco"

Get-ChildItem $chocoTempDir -Filter *.zip |
Foreach-Object{
   Expand-ZIPFile $_.FullName  $chocoDir
}

$toolsFolder = Join-Path $chocoDir "tools"
$chocoInstallPS = Join-Path $toolsFolder "chocolateyInstall.ps1"

try {
  Write-Output "Installing Chocolatey ..."
  & $chocoInstallPS
}
catch {
  Write-Error "Could not install chocolatey. Exiting now!"
  exit 1
}

Set-Location "C:\"
Remove-Item -Recurse -Force $chocoTempDir

## =======================================
if ( $proxy -ne "" -and $proxy -ne $null) {
  choco config set proxy $proxy
}

if ( $chocoRepo -ne "" -and $chocoRepo -ne $null ) {
  #choco source disable -y --name="chocolatey"
  choco source add -y --name='internal' --source=$chocoRepo --priority=1
}

try {
  Write-Output "Installing ruby ..."
  choco install -y ruby
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  Write-Output "Installing nuget.commandline ..."
  choco install -y nuget.commandline
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  Write-Output "Installing ruby2.devKit ..."
  choco install -y ruby2.devkit
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
catch {
  Write-Error "Could not install one or more choco packages"
  exit 1
}
###########################################

Set-Location "C:\tools\DevKit2\"
Add-Content config.yml "`n- C:/tools/ruby23"

###########################################

if ($($env:Path).ToLower().Contains("ruby") -eq $false) {
  [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\ruby23\bin", [EnvironmentVariableTarget]::Machine)
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

if ($($env:Path).ToLower().Contains("devkit") -eq $false) {
  [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\tools\DevKit2\bin", [EnvironmentVariableTarget]::Machine)
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

ruby dk.rb install

if ( $gemRepo -ne "" -and $gemRepo -ne $null) {
    gem source --add $gemRepo
    gem source -r https://rubygems.org/
}

try {
  Write-Output "Installing json ..."
  gem install json --version 1.8.2 --no-ri --no-document

  #Write-Output "Installing Bundler ..."
  #gem install bundler --version 1.10.5 --no-ri --no-rdoc
}
catch {
  Write-Error "Could not install one or more gems"
  exit 1
}

#Add-Content C:\cygwin64\home\Administrator\.bash_profile 'export PATH=$PATH:/cygdrive/c/ProgramData/chocolatey/bin:/cygdrive/c/tools/ruby23/bin:/cygdrive/c/tools/DevKit2/bin'
#New-Item -ItemType Directory -Force -Path C:\cygwin64\opt\Administrator\workorder\

Add-Content C:\cygwin64\home\oneops\.bash_profile 'export PATH=$PATH:/cygdrive/c/ProgramData/chocolatey/bin/:/cygdrive/c/tools/ruby23/bin:/cygdrive/c/tools/DevKit2/bin'
New-Item -ItemType Directory -Force -Path C:\cygwin64\opt\oneops\workorder\
New-Item -ItemType Directory -Force -Path C:\cygwin64\etc\nagios\conf.d\

New-Item C:\cygwin64\opt\oneops\rubygems_proxy -type file -force
Set-Content C:\cygwin64\opt\oneops\rubygems_proxy $gemRepo

#grant full access on Cygwin folders to oneops user
@("\var\lib", "\var\cache", "\var\run", "\etc", "\opt") | % {takeown /F C:\Cygwin64$_ /D Y /R}
@("\var\lib", "\var\cache", "\var\run", "\etc", "\opt") | % {icacls C:\Cygwin64$_ /grant oneops:`(OI`)`(CI`)F /T /C}

Set-Location "C:\"
Write-Output "End of windows install_base script"
