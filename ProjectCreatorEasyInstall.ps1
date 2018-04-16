##############################
#.SYNOPSIS
# Script that performs the install and setup for TheCodeAttic.Helix.PowerShellProjectCreator.
# Task accomplished are:
#       1. Module folder checked for and created if it does not exist at the current users PowerShell Profile location
#       2. Download from GitHub the PowerShell Module "TheCodeAttic.Helix.PowerShellProjectCreator.psm1" and saves to above location
#       3. Checks the current users PowerShell Profile location for a NuGet_profile.ps1 file
#       4. Creates the NuGet_profile.ps1 if it does not exist
#       5. Appends the Import-Module command for 'TheCodeAttic.Helix.PowerShellProjectCreator' module.
#
#.DESCRIPTION
# Script that performs the install and setup for TheCodeAttic.Helix.PowerShellProjectCreator.
# Task accomplished are:
#       1. Module folder checked for and created if it does not exist at the current users PowerShell Profile location
#       2. Download from GitHub the PowerShell Module "TheCodeAttic.Helix.PowerShellProjectCreator.psm1" and saves to above location
#       3. Checks the current users PowerShell Profile location for a NuGet_profile.ps1 file
#       4. Creates the NuGet_profile.ps1 if it does not exist
#       5. Appends the Import-Module command for 'TheCodeAttic.Helix.PowerShellProjectCreator' module.
#
#.EXAMPLE
# > Invoke-ProjectCreatorEasyInstall
#
#.NOTES
# n/a
##############################
function Invoke-ProjectCreatorEasyInstall{
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
}

Invoke-ProjectCreatorEasyInstall
