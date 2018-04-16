$ModuleFolderName = 'TheCodeAttic.Helix.PowerShellProjectCreator'
$ModulePath =($env:PSModulePath).Split(";")[0] + "\$ModuleFolderName"

if(-NOT (Test-path -Path $ModulePath))
{
   Write-Host "$ModuleFolderName does not exist, so will be created at $ModulePath" -ForegroundColor 'Green'
   New-Item -Path ($env:PSModulePath).Split(";")[0] -ItemType Directory -Name $ModuleFolderName
}

Write-Host "Download and save $ModuleFolderName" -ForegroundColor 'Green'
(Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/master/HelixProjectCreator.psm1).Content | Out-File $(Join-Path $ModulePath "$ModuleFolderName.psm1") -Force

Write-Host "Update and create the NuGet profile"
$profilePath = Split-Path $profile
$NuGetProfilePath = Join-Path $profilePath "NuGet_profile.ps1"
$ImportModuleCommand = "Import-Module $ModuleFolderName"


if(-NOT (Test-path -Path $NuGetProfilePath))
{
   Write-Host "NuGet_profile.ps1 does not exist, so will be created at $NuGetProfilePath" -ForegroundColor 'Green'
   $ImportModuleCommand | Out-File $NuGetProfilePath
}
else
{
  Write-Host "NuGet_profile.ps1 does exist, updating with Import-Module command" -ForegroundColor 'Green'
  Add-Content -Path $NuGetProfilePath -value $ImportModuleCommand
}
