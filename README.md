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

1. Download (https://github.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/blob/master/Helix.ProjectCreator.psm1) to your local system in the manner that suits your workflow the best.
2. Each time you wish to leverage the module in Visual Studio you will need to enter the following in the Package Manager Console

````PowerShell
Import-Module "C:\MyFiles\THelix.ProjectCreator.psm1"
````

### Setup and Configure the Manual Way

OR you could download and configure the module manually each time (this is what ProjectCreatorEasyInstall.ps1 does for you.)

1. Go to C:\Users\<CURRENT USER DIRECTORY>\Documents\WindowsPowerShell\Modules
2. Create a new folder called "Helix.ProjectCreator"
3. Download (https://github.com/gillissm/TheCodeAttic.Helix.PowerShellProjectCreator/blob/master/Helix.ProjectCreator.psm1) into the above directory
4. Go up a level in the file system, should be at C:\Users\<CURRENT USER DIRECTORY>\Documents\WindowsPowerShell\
5. Open (or create) NuGet_profile.ps1
6. Add the following

````PowerShell
Import-Module Helix.ProjectCreator
````

7. Each time you run Visual Studio the module will be available to use in the Package Console Manager

## Using the Script to Manage Helix Solution

Because the script leverages the native DTE Interface of Visual Studio is can be used to create new solutions, as well as modify existing solutions without any additional tweaks to the code.

### Confirm Module Has Loaded

The following will allow you to confirm that the module is accessible for usage. This check is most helpful the first time one has used it after leveraging the easy install script.

```PowerShell
Get-Module Helix.ProjectCreator -ListAvailable
```

![Confirm Module is Loaded](helix-helix-image3.png)

## Create a new Helix Solution

1. Open Visual Studio as Admin
2. Open the Package Manager Console
3. Create a new Helix based solution by running Invoke-VisualStudioSolution
   * Include the parameter '-SolutionName', this will be the name of the VS solution as well the name given to the directory create for the solution
   * Include the parameter '-DirectoryPath', this is the fully qualified path to the parent directory the solution should be created at

````PowerShell
> Invoke-VisualStudioSolution -SolutionName HelixAttic.Sample -DirectoryPath C:\Code\git-TheCodeAttic\
````

![New Solution and File Structure](helix-image4.png)

## Add a new module to a solution

1. Open Visual Studio as Admin
2. Open your Solution
3. Open the Package Manager Console
4. Add new module by running Invoke-NewModule
    * Set parameter *-ModuleName* to the name of the module/component, this should NOT include the full namespace, as this will be generated automatcially based on solution name
    * Select a value for *-Layer* from the provided list (Feature, Foundation, Project) depending on need
    * Optionally include the *-UseUnicorn*  or *-UseTDS* flag to setup the corresponding serialization requirements

````PowerShell
Invoke-NewModule -ModuleName PageContent -Layer Feature -UseUnicorn
````

![New Module with Unicorn](helix-image5.png)

### Add a new empty module to a solution

In addition to creating a project with folders and NuGet references, the script can add a blank or empty project with the given name to the solution by including the flag *-CreateEmptyProject*.

````PowerShell
Invoke-NewModule -ModuleName PlaceHolder -Layer Foundation -CreateEmptyProject
````

![New Empty Module](helix-image6.png)

See the module file for a listing of all optional parameters, including the ability to set a specific Sitecore version.

## Other Cmdlets of interest

### Invoke-SerializationProject

Call this to setup Unicorn or TDS project for a given module. When calling, be sure to include the full project name (with namespace).

````PowerShell
Invoke-SerializationProject -ProjectName HelixAttic.Sample.Foundation.PlaceHolder -UseUnicorn
````

### Invoke-CreateNewModuleProject

Call this to add an empty project to the solution for a layer, this is the same as calling *Invoke-NewModule* with the 'CreateEmptyProject' flag.

Now go create some awesome Sitecore code with confidence!
