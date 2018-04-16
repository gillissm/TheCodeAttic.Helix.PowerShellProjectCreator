# TheCodeAttic.Helix.PowerShellProjectCreator

*Helix* (http://helix.sitecore.net) is a set of overall design principles and conventions for Sitecore development, put forth by Sitecore in hopes of providing the community a path toward standardized solution development.

As part of this principle there are expected file system and Visual Studio Solution structures that are to be used, which can be time intensive to setup. This script is meant to be a utility to ease this setup process.

## Setup and Configure from Script

To make adaption as easy as possible I've simplified setup to the following three steps for you:

1. Open PowerShell command prompt as Admin.
2. Change the directory to a working/temporary location
3. Enter the following

````PowerShell
(Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/master/ProjectCreatorEasyInstall.ps1).Content | Out-File "ProjectCreatorEasyInstall.ps1"````
.\ProjectCreatorEasyInstall.ps1
````

### Setup and Use the Simple Manual Process

As an alternate to the above, you can pull the script from GitHub and run load it into Package Manager Console each time you need it with the following steps:

1. Download (https://github.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/blob/master/HelixProjectCreator.psm1) to your local system in the manner that suits your workflow the best.
2. Each time you wish to leverage the module in Visual Studio you will need to enter the following in the Package Manager Console

````PowerShell
Import-Module "C:\MyFiles\TheCodeAttic.Helix.PowerShellProjectCreator.psm1"
````

### Setup and Configure the Manual Way

OR you could download and configure the module manually each time (this is what ProjectCreatorEasyInstall.ps1 does for you.)

1. Go to C:\Users\<CURRENT USER DIRECTORY>\Documents\WindowsPowerShell\Modules
2. Create a new folder called "TheCodeAttic.Helix.PowerShellProjectCreator"
3. Download (https://github.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/blob/master/HelixProjectCreator.psm1) into the above directory
4. Go up a level in the file system, should be at C:\Users\<CURRENT USER DIRECTORY>\Documents\WindowsPowerShell\
5. Open (or create) NuGet_profile.ps1
6. Add the following

````PowerShell
Import-Module TheCodeAttic.Helix.PowerShellProjectCreator
````

7. Each time you run Visual Studio the module will be available to use in the Package Console Manager

## Using Project Creator

### Create a new Helix Solution

1. Open Visual Studio as Admin
2. Open the Package Manager Console
3. Create a new Helix based solution by running Invoke-VisualStudioSolution

````PowerShell
Invoke-VisualStudioSolution -SolutionPath 'C:\Code\Coffeehouse.Demo.SXA'  -SolutionName 'Coffeehouse.Demo.SXA'
````

### Add a new module to a solution

1. Open Visual Studio as Admin
2. Open your Solution
3. Open the Package Manager Console
4. 'Wake-up' the $dte object by running

````PowerShell
$dte.Solution.FullName
````

5. Add new module by running Invoke-NewModule

````PowerShell
Invoke-NewModule -ModuleName 'Coffeehouse.Demo.SXA.Coupon' -Layer 'Feature' -UseGlass -UseTDS
````

6. Go write some Sitecore code!!!!
