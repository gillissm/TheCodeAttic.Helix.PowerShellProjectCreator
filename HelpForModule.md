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
    Invoke-NewModule -ModuleName "Ad" -Layer "Feature"
````

### -------------------------- EXAMPLE 2 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -UseTDS
````

### -------------------------- EXAMPLE 3 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -UseUnicorn
````

### -------------------------- EXAMPLE 4 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -SitecoreVersion "8.2.171121"
````

### -------------------------- EXAMPLE 5 --------------------------

````PowerShell
    Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseUnicorn
````

## Invoke-SerializationProject

### SYNOPSIS

Creates a serialization project for the named module

### -------------------------- EXAMPLE 1 --------------------------

````PowerShell
    Invoke-SerializationProject -ProjectName "Coffeehouse.Foundation.Search" -Layer "Foundation" -UseTDS
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

Creates a new Visual Studio Solution at the given Directory Path with base folders

 File System will look like the following
 - Directory Path
 -- Solution Name
 -- SolutionName.sln
 -- lib
 -- __Documents
 -- __Scripts
 -- src
 --- Feature
 --- Foundation
 --- Project

### -------------------------- EXAMPLE 1 --------------------------

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

