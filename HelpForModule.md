# TheCodeAttic.Helix.PowerShellProjectCreator Module Method Help Guide

## Get-ProjectItem

### SYNOPSIS

Performs a recursive search through a Visual Studio Project Item's ProjectItems collection for the given item name.
All branches are searched looking for the first return of the item
If no item is found then $null is returned.

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    $project = Get-Project 'Coffeehouse.Feature.CouponCode'
    Get-ProjectItem -ProjectItem $project -ItemName 'App_Config'
````

## Get-SolutionFolder

### SYNOPSIS

Recursively loops through the current Solution as defined by $dte.Solution object for a project itme of type 'Solution Folder' with the given name.

The found folder is returned as a [nvDTE80.SolutionFolder] object

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Get-SolutionFolder 'Feature'
````

## Get-VisualStudioTemplate

### SYNOPSIS

Returns the filename and path of a given Visual Studio Template as requested.
An additional filter value can be supplied to check that the path of the template matches a specific location/type

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    $DefaultVisualStudioInstall = 'C:\Program\VS'    
    Get-VisualStudioTemplate -TemplateName 'TDS Project.vstemplate'
    'C:\Program\VS\Templates\TDSProject.vstemplate'
````
### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Get-VisualStudioTemplate -TemplateName 'Class.vstemplate' -FilterValue '*Web\CSharp*
    'C:\Program\VS\Templates\Custom\Web\cSharp\Class.vstemplate'
````

## Invoke-CreateModule
    
### SYNOPSIS
    
Creates a new Empty Web Application Project named $ModuleName, under the $Layer folder 

IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:

````PowerShell
    $dte.Solution.FullName
````

If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Invoke-CreateModule -ModuleName "Coffeehouse.Foundation.Search" -Layer "Foundation"
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-CreateModule "Coffeehouse.Foundation.Search" "Foundation"
````

## Invoke-ModuleFileSetup

### SYNOPSIS

Performs a number of different steps in setting up and configuring the Module Web project.

#### STEP 1

Configures the following for the project:

* Web.config build action is set to NONE
* Set Target .NET Framework to given value or default of 4.7.1
* NuGet Install of - Microsoft.AspNet.MVC
* NuGet Install of - Sitecore.Kernel.NoReferences
* NuGet Install of - Sitecore.Mvc.NoReferences
* NuGet Install of - Sitecore.Logging.NoReferences
* NuGet Install of -  Microsoft.Extensions.DependencyInjection.Abstractions version 1.0.0
* NUGet Install of - Galss.Mapper.Sc if required (default is NOT to install)
* Set all Reference DLLs to be Copy Local = False

#### STEP 2

Adds a Module specific config file to App_Config -> Include -> $Layer, which is then configured for Dependecny Register class

#### STEP 3

Adds default folders to a Helix based project for 
* DI
* Views
* Views\$ModuleName
* Repositories
* Constants
* Controllers
* Models

#### STEP 4

Creates a RegisterContainer.cs file inside the folder 'DI' with the default logic

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Invoke-ModuleFileSetup "Coffeehouse.Featuer.ShoppingHistory" "Feature" -UseGlass
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-ModuleFileSetup -ModuleName "Coffeehouse.Featuer.ShoppingHistory" -Layer "Feature" -UseGlass
````

## Invoke-NewModule

### SYNOPSIS

Create and setup a new module project into any layer with the option for assocated serialization projects/folders to be created.

IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:

````PowerShell
    $dte.Solution.FullName
````

If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    >Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -UseGlass -UseTDS
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121"
````

### -------------------------- EXAMPLE 3 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseGlass -UseTDS
````

### -------------------------- EXAMPLE 4 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseGlass -UseUnicorn
````

### -------------------------- EXAMPLE 5 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseTDS
````

## Invoke-SerializationProject

### SYNOPSIS

Creates a serialization project for the named module

IMPORTANT: Script only creates TDS projects currently that are always module Name 'Master'

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Invoke-SerializationProject -ModuleName "Coffeehouse.Foundation.Search" -Layer "Foundation" -UseTDS
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-SerializationProject "Coffeehouse.Foundation.Search" "Foundation" -UseTDS
````

## Invoke-SolutionRootPath

### SYNOPSIS

Retrieves the active solutions path to its 'src' folder

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    $rootPath = Invoke-SolutionRootPath
    $rootPath
    C:\Code\Coffeehouse.Demo.SC9\src
````

## Invoke-ViusalStudioSolution

### SYNOPSIS

Creates a new Visual Studio Solution and adds basic Helix solution and file system folders.

File System will look like the following
    - Directory Path
    -- SolutionName
    -- SolutionName.sln
    -- lib
    -- src
    --- __Documents
    --- __Scripts
    --- Feature
    --- Foundation
    --- Project

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-VisualStudioSolution -SolutionPath "C:\Code" -SolutionName "Coffeehouse.Demo.SC9"
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-VisualStudioSolution "C:\Code" "Coffeehouse.Demo.SC9"
````

## Write-StepHeader

### SYNOPSIS

Writes a message in the following format to the screen, useful for delineating major steps taken. This will span the entire screen width.
    [ ------------- $TASKNAME : $TASKTYPE ------------]

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Write-StepHeader -TaskName "Create the World" -TaskType "Creation"
````

## Write-StepInfo

### SYNOPSIS

Writes text to the screen in the format:
    [$Tag] $Message

If $TextColor is set the foreground color of the message will be shown as this value

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Write-StepInfo -TaskInfo "Step 1" -Message "Hello World loading."
    [Step 1] Hello World loading.
````
