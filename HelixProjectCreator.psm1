Set-StrictMode -Version 2.0

#Private Logic Methods
##############################
#.SYNOPSIS
# Saves the current Visual Studio Solution based on $dte.Solution.FullName
#
#.DESCRIPTION
# Saves the current Visual Studio Solution based on $dte.Solution.FullName
#
#.EXAMPLE
# 
# #To Run
# > Save-VisualStudioSolution
#
#.NOTES
# Private Method
##############################
function Save-VisualStudioSolution {
    try{
        $dte.Solution.SaveAs($dte.Solution.FullName)
        Write-StepInfo -Tag "$($dte.Solution.FullName)" -Message 'Successfully saved.'  
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Returns the file name and path of a given Visual Studio Template as requested.
# An additional filter value can be supplied to check that the path of the template matches a specific location/type
#
#.DESCRIPTION
# Returns the file name and path of a given Visual Studio Template as requested.
# An additional filter value can be supplied to check that the path of the template matches a specific location/type
#
#.PARAMETER TemplateName
# Name of the Template to be found
#
# REQUIRED
#
# ex: webconfig.vstemplate
#
#.PARAMETER DefaultVisualStudioInstall
# Path to where Templates have been installed.
# Default is to a 2017 Visual Studio Installation
# DEFAULT VALUE: 'C:\Program Files (x86)\Microsoft Visual Studio\2017'
#
# OPTIONAL
#
# ex: 'C:\Program Files (x86)\Microsoft Visual Studio\2017'
#
#.PARAMETER FilterValue
# Value of filter that the path should include.
# Used to limit similar named templates to a specific version
# 
# OPTIONAL
#
# ex: '*Web\CSharp\*'
#
#.EXAMPLE
# > $DefaultVisualStudioInstall = 'C:\Program\VS'
# > Get-VisualStudioTemplate -TemplateName 'TDS Project.vstemplate'
# > 'C:\Program\VS\Templates\TDSProject.vstemplate'
#
# > Get-VisualStudioTemplate -TemplateName 'Class.vstemplate' -FilterValue '*Web\CSharp*
# > 'C:\Program\VS\Templates\Custom\Web\cSharp\Class.vstemplate'
#
#.NOTES
# Private Method
##############################
function Get-VisualStudioTemplate{
	param( 
        [parameter(Position=0, Mandatory=$true)]
		[string]$TemplateName,
        [parameter(Mandatory=$false)]
        [string]$DefaultVisualStudioInstall='C:\Program Files (x86)\Microsoft Visual Studio\2017',        
		[parameter(Mandatory=$false)]
		[string]$FilterValue
            )
        try{
            if($FilterValue)
            {
                return (Get-ChildItem -Path $DefaultVisualStudioInstall -Filter $TemplateName -Recurse -ErrorAction SilentlyContinue -Force | Where-Object{$_.FullName -like $FilterValue} | Select-Object -First 1).FullName
            }
            else {
                return (Get-ChildItem -Path $DefaultVisualStudioInstall -Filter $TemplateName -Recurse -ErrorAction SilentlyContinue -Force| Select-Object -First 1).FullName    
            }	
        }
        catch {
            # Write the error information then rethrow
            # We need the error information in the log
            # The rethrow is for any calling script
            Write-Error $_ -ErrorAction Continue
            throw
        }
}

##############################
#.SYNOPSIS
# Recursively loops through the current Solution as defined by $dte.Solution object for a project itme of type 'Solution Folder' with the given name.
# The found folder is returned as a [nvDTE80.SolutionFolder] object
#
#.DESCRIPTION
# Recursively loops through the current Solution as defined by $dte.Solution object for a project itme of type 'Solution Folder' with the given name.
# The found folder is returned as a [nvDTE80.SolutionFolder] object
#
#.PARAMETER ItemName
# Name of the Solution Folder to be returned
#
# REQUIRED
#
#.EXAMPLE
# > Get-SolutionFolder 'Feature'
#
#.NOTES
# Public Method
##############################
function Get-SolutionFolder
{
	param(  [parameter(Mandatory=$true)]
			[string]$ItemName)
	try{

        return $dte.Solution.Projects | Where-Object{$_.Name -eq $ItemName} | Select-Object -First 1

        # for ($i = 1; $i -lt $dte.Solution.Projects.Count+1; $i++) {
        #     if($dte.Solution.Projects.Item($i).Name -eq $ItemName){
        #         return Get-Interface $dte.Solution.Projects.Item($i).Object ([EnvDTE80.SolutionFolder])
        #             #return ConvertTo-SolutionFolder $dte.Solution.Projects.Item($i).Object
        #     }
        # }
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Takes an object and properly converts to a Visual Studio Solution Folder Object
#
#.DESCRIPTION
# Takes an object and properly converts to a Visual Studio Solution Folder Object
#
#.PARAMETER objectForConvert
# Object to convert to a Solution Folder object
#
#.EXAMPLE
# > $folderObject = ConvertTo-SolutionFolder ($dte.Solution.Projects.Item(1)).Object
#
# > $newFolder = $dte.Solution.AddSolutionFolder("My New Folder");
# > $folderObject = ConvertTo-SolutionFolder $newFolder.Object
#
#.NOTES
# Public Method
##############################
function ConvertTo-SolutionFolder
{
    param(
        [parameter(Position=0, Mandatory=$true)]
        [object]$objectForConvert
    )
    return Get-Interface $objectForConvert ([EnvDTE80.SolutionFolder])
}

##############################
#.SYNOPSIS
# Performs a recursive search through a Visual Studio Project Item's ProjectItems collection for the given item name.
# All branches are searched looking for the first return of the item
# If no item is found then $null is returned.
#
#.DESCRIPTION
# Performs a recursive search through a Visual Studio Project Item's ProjectItems collection for the given item name.
# All branches are searched looking for the first return of the item
# If no item is found then $null is returned.
#
#.PARAMETER ProjectItem
# Visual Studio Project Item object whose children should be searched
#
# REQUIRED
#
#.PARAMETER ItemName
# Name of the item to be found
#
# REQUIRED
#
#.EXAMPLE
# > $project = Get-Project 'Coffeehouse.Feature.CouponCode'
# > Get-ProjectItem -ProjectItem $project -ItemName 'App_Config'
#
#.NOTES
#General notes
##############################
function Get-ProjectItem{
    param(  
        [parameter(Mandatory=$true)]
        [object]$ProjectItem,
        [parameter(Mandatory=$true)]
        [string]$ItemName
        )
    try{
        if($ProjectItem.Name -eq $ItemName){
            Write-StepInfo -Tag "$ItemName" -Message "Found project item"
            return $ProjectItem
        }

        if($ProjectItem.ProjectItems.Count -ge 1)
        {
            foreach($pi in $ProjectItem.ProjectItems)
            {
                $temp = Get-ProjectItem $pi $ItemName
                if($temp -ne $null)
                {                   
                    return $temp
                }
            }        
        }
        return $null
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}


##############################
#.SYNOPSIS
# Adds a folder to the Visual Studio Project Item if the folder does not already exist.
# Folders added this way also are added to the file system.
# The created folder is then returned for usage in other scripts.
#
#.DESCRIPTION
# Adds a folder to the Visual Studio Project Item if the folder does not already exist.
# Folders added this way also are added to the file system.
# The created folder is then returned for usage in other scripts.
#
#.PARAMETER ProjectItem
# Visual Studio Project Item (could be a folder, soltuion, or project) that the new folder is to be added to
#
# REQUIRED
#
#.PARAMETER FolderName
# Name of the new folder to be added
#
# REQUIRED
#
#.EXAMPLE
# > $project = Get-Project 'Coffeehouse.Feature.CouponCode'
# > Add-FolderToProjectItem -ProjectItem $proj -FolderName 'Controllers'
#
#.NOTES
# Private Method
##############################
function Add-FolderToProjectItem{
    Param(
		[Parameter(Position=0, Mandatory=$True)]
        [object]$ProjectItem,
        [Parameter(Position=1, Mandatory=$True)]
        [string]$FolderName
    )
    try{
        $folderItem = Get-ProjectItem -ProjectItem $ProjectItem -ItemName $FolderName

        if($folderItem -eq $null)
        {
            Write-StepInfo -Tag $FolderName -Message 'Created new folder.'
            $folderItem = $ProjectItem.ProjectItems.AddFolder($FolderName)
        }
        else {
            Write-StepInfo -Tag $FolderName -Message 'Folder already existed'
        }

        return $folderItem
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }

}


##############################
#.SYNOPSIS
# Creates a new Visual Studio Solution at the given Directory Path with base folders
#
# File Systme will look like the following
# - Directory Path
# -- Solution Name
# -- SolutionName.sln
# -- lib
# -- src
# --- __Documents
# --- __Scripts
# --- Feature
# --- Foundation
# --- Project
#
#.DESCRIPTION
# Creates a new Visual Studio Solution at the given Directory Path with base folders
#
# File Systme will look like the following
# - Directory Path
# -- Solution Name
# -- SolutionName.sln
# -- lib
# -- src
# --- __Documents
# --- __Scripts
# --- Feature
# --- Foundation
# --- Project
#
#.PARAMETER SolutionName
# Name of the Visual Studio Solution, will also be used for a solution folder creation
#
# REQUIRED
#
#.PARAMETER DirectoryPath
# File system path to where the solution will be create at.
#
# REQUIRED
#
#.PARAMETER FoundationLayerFolder
# Folder Name that will be the parent to 'foundation' layer modules. 
# A Solution Folder by this name will be created as will a folder on the file system.
#
# DEFAULT: Foundation
#
# OPTIONAL
#
#.PARAMETER FeatureLayerFolder
# Folder Name that will be the parent to 'feature' layer modules. 
# A Solution Folder by this name will be created as will a folder on the file system.
#
# DEFAULT: Feature
#
# OPTIONAL
#
#.PARAMETER ProjectLayerFolder
# Folder Name that will be the parent to 'project' layer modules. 
# A Solution Folder by this name will be created as will a folder on the file system.
#
# DEFAULT: Project
#
# OPTIONAL
#
#.EXAMPLE
# > New-VisualStudioSoltion -SolutionName 'Helix.Demo.Solution' -DirectoryPath 'C:\Code\MySamples'
#
# >  New-VisualStudioSoltion -SolutionName 'Helix.Demo.Solution' -DirectoryPath 'C:\Code\MySamples' -FoundationLayerFolder "SharedModules" -FeatureLayerFolder "CustomStuff" -ProjectLayerFolder "Core"
#.NOTES
#Private Method
##############################
function New-VisualStudioSolution{
    param(
		[parameter(Position=0, Mandatory=$true)]
		[string]$SolutionName,
		[parameter(Position=1,Mandatory=$true)]
        [string]$DirectoryPath,
        [parameter(Mandatory=$false)]
        [string]$FoundationLayerFolder = 'Foundation',
        [parameter(Mandatory=$false)]
        [string]$FeatureLayerFolder = 'Feature',
        [parameter(Mandatory=$false)]
        [string]$ProjectLayerFolder = 'Project'
	)
    try{
        #CHECK DIRECTORY, CREATE IF NEEDED
        if(-NOT (Test-path -Path $DirectoryPath))
        {
            Write-StepInfo -Tag $SolutionName -Message "Solution directory does not exist, going to create it"
            New-Item -Path $DirectoryPath -ItemType Directory
        }
        
        $slnPath =  ($DirectoryPath +'\'+ $SolutionName)
        #CHECK DIRECOTORY for SOLTUION FOLDER
        if(-NOT (Test-Path -Path $slnPath))
        {
            New-Item -Path $slnPath -ItemType Directory
        }

        $slnNameExt =$SolutionName + '.sln'

        #CREATE SOLUTION
        Write-StepInfo -Tag $SolutionName -Message "Creating and saving solution"
        $dte.Solution.Create($slnPath, $slnNameExt)
        $dte.Solution.SaveAs($slnPath + '\' + $slnNameExt)
        
        #CREATE FILE SYSTEM and MATCHING SOLUTION FOLDERS
        #- create SRC folder    
        $slnSrcPath = (New-Item -Path $slnPath -Name 'src' -ItemType Directory).FullName
        #- create Feature Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create Feature folder in solution and on file system'
        $FeatureFlderPath = (New-Item -Path $slnSrcPath -Name $FeatureLayerFolder -ItemType Directory).FullName
        $dte.Solution.AddSolutionFolder($FeatureLayerFolder)
        #- create Foundation Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create Foundation folder in solution and on file system'
        $FeatureFlderPath = (New-Item -Path $slnSrcPath -Name $FoundationLayerFolder -ItemType Directory).FullName
        $dte.Solution.AddSolutionFolder($FoundationLayerFolder)
        #- create Project Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create Project folder in solution and on file system'
        $FeatureFlderPath = (New-Item -Path $slnSrcPath -Name $ProjectLayerFolder -ItemType Directory).FullName
        $dte.Solution.AddSolutionFolder($ProjectLayerFolder)
        #- create __Documents Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create __Documents folder in solution and on file system'
        $FeatureFlderPath = (New-Item -Path $slnSrcPath -Name '__Documents' -ItemType Directory).FullName
        $dte.Solution.AddSolutionFolder('__Documents')
        #- create __Scripts Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create __Scripts folder in solution and on file system'
        $FeatureFlderPath = (New-Item -Path $slnSrcPath -Name '__Scripts' -ItemType Directory).FullName
        $dte.Solution.AddSolutionFolder('__Scripts')
        #- create  lib Folder
        Write-StepInfo -Tag $SolutionName -Message 'Create lib folder on file system'
        $FeatureFlderPath = (New-Item -Path $slnPath -Name 'lib' -ItemType Directory).FullName

        #SAVE AS REQUIRED TO ENSURE CHANGES TAKE AFFECT
        Save-VisualStudioSolution
        
        $slnFullPath = $slnPath + '\' + $slnNameExt
        return $slnFullPath
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Creates a new project within the solution with a name as defined by ModuleName.
#
#.DESCRIPTION
# Creates a new web project within the solution with a name as defined by ModuleName.
#
#.PARAMETER ModuleName
# Name of the project (or module being added)
#
# REQUIRED
#
#.PARAMETER Layer
# Type of module (normally Feature, Foundation, or Project).
# This should match similar values as the folder structure has been defined for seperateion.
#
# REQUIRED
#
#.PARAMETER ModuleProjectTemplate
# Path and File name to the project template that is to be created.
# This value is normally retreived via a call to Get-VisualStudioTemplate
#
# REQUIRED
#
#.PARAMETER SourceCodeRootPath
# Full path to the parent locaiton of Module Type folders
# 
# ex: 'C:\Code\MySamples\Helix.Demo.Solution\src'
#
# REQUIRED
#
#.PARAMETER SourceCodeFolderName
# Value that project code should be placed in.
#
# DEFAULT VALUE: code 
#
# OPTIONAL
#
#.EXAMPLE
# > Add-Module -ModuleName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -ModuleProjectTemplate 'C:\Program\VS\2017\WebApp.vstemplate' -SourceCodeRootPath 'C:\Code\Coffeehouse\src'
#
# > Add-Module -ModuleName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -ModuleProjectTemplate 'C:\Program\VS\2017\WebApp.vstemplate' -SourceCodeRootPath 'C:\Code\Coffeehouse\src' -SourceCodeFolderName 'codefolder'
#
#.NOTES
# Private Method
##############################
function Add-Module
{
	Param(
		[Parameter(Position=0, Mandatory=$True)]
		[string]$ModuleName,
		[Parameter(Position=1, Mandatory=$True)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,
		[Parameter(Position=2, Mandatory=$True)]
        [string]$ModuleProjectTemplate='C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\ProjectTemplates\CSharp\Web\1033\WebApplicationProject40\EmptyWebApplicationProject40.vstemplate',
        [Parameter(Position=3, Mandatory=$True)]
        [string]$SourceCodeRootPath,
        [Parameter(Position=4, Mandatory=$false)]
        [string]$SourceCodeFolderName = 'code'
		)	
	try
	{
        Write-StepInfo -Tag "$ModuleName" -Message "Save Solution to ensure it is clean before project creation"
        Save-VisualStudioSolution

        #Check that the module does not already exist in solution
        $slnFolderObj= Get-SolutionFolder $ModuleName
        if($slnFolderObj -ne $null){
            Write-StepInfo -Tag "$ModuleName" -Message "Folder with module name already exists in solution."
            Write-StepInfo -Tag "$ModuleName" -Message "$ModuleName will not be created."
            return
        }

        #Check that the project does not exist on the file system
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Path format: {0}\{1}\{2}\{3}"
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Part 0: $SourceCodeRootPath"
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Part 1: $Layer"
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Part 2: $ModuleName"   
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Part 3: $SourceCodeFolderName"   
        $modulePath = "{0}\{1}\{2}\{3}" -f $SourceCodeRootPath, $Layer, $ModuleName, $SourceCodeFolderName
        Write-StepInfo -Tag "$ModuleName - Path Creation" -Message "Final Path: $modulePath"   

        if(Test-Path $modulePath){
            Write-StepInfo -Tag "$ModuleName" -Message "$modulePath exists on the file system"
            Write-StepInfo -Tag "$ModuleName" -Message "$ModuleName will not be created."
            return
        }

        #Project does not exist in the solution or file system so safe to create
        $layerFolder = Get-SolutionFolder $Layer 	
        if($layerFolder -eq $null){
            Write-StepInfo -Tag "$ModuleName" -Message "$Layer solution folder does not exist."
            Write-StepInfo -Tag "$ModuleName" -Message "$ModuleName will not be created."
            return
        }
        
        Write-StepInfo -Tag "$ModuleName - Layer Folder" -Message "$($layerFolder.ProjectName)"        
        $sf = $layerFolder.Object.AddSolutionFolder($ModuleName)           
        Write-StepInfo -Tag "$ModuleName - Save Solution" -Message "Saving Solution after folder add"        
        Save-VisualStudioSolution

        Write-StepInfo -Tag "$ModuleName - Module Folder" -Message "$($sf.ProjectName)"        
        Write-StepInfo -Tag "$ModuleName - Project Creation" -Message "Template: $ModuleProjectTemplate"
        Write-StepInfo -Tag "$ModuleName - Project Creation" -Message "Path: $modulePath"
        Write-StepInfo -Tag "$ModuleName - Project Creation" -Message "Name: $ModuleName"

        $layerFolder = Get-SolutionFolder $Layer
        $sp = Get-ProjectItem $layerFolder $ModuleName
        if(-NOT $sp){
            Write-StepInfo -Tag "$ModuleName " -Message "Solution Folder for Module Not Found"
            return
        }
        $sp.SubProject.Object.AddFromTemplate($ModuleProjectTemplate, $modulePath, $ModuleName)

        Write-StepInfo -Tag "$ModuleName - Save Solution" -Message "Saving Solution after project add"
		Save-VisualStudioSolution
        Write-StepInfo -Tag $ModuleName -Message "Module created: $modulePath"
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Performs a NuGet Package Install (ie Install-Package) to the given project ($ModuleName).
# If no $PackageVersion is given the latest version is installed.
#
#.DESCRIPTION
# Performs a NuGet Package Install (ie Install-Package) to the given project ($ModuleName).
# If no $PackageVersion is given the latest version is installed.
#
#.PARAMETER ModuleName
# Name of the project the NuGet package should be installed against
#
# REQUIRED
#
#.PARAMETER PackageName
# Name of NuGet Package to be installed
#
# REQUIRED
#
#.PARAMETER PackageVersion
# Version number of the package that should be installed
# If NO version is provided then the latest version will be isntalled of the package
#
# OPTIONAL 
#
#.EXAMPLE
# > Add-PackageToModule -ModuleName 'Coffeehouse.Feature.CouponCode' -PackageName 'Sitecore.Kernel.NoReference'
#
# > Add-PackageToModule -ModuleName 'Coffeehouse.Feature.CouponCode' -PackageName 'Microsoft.Extensions.DependencyInjection.Abstraction' -PackageVersion '1.0.0'
#
#.NOTES
#Private Method
##############################
function Add-PackageToModule{
    Param(
		[Parameter(Position=0, Mandatory=$True)]
        [string]$ModuleName,
        [Parameter(Position=1, Mandatory=$True)]
        [string]$PackageName,
        [Parameter(Position=2, Mandatory=$false)]
        [string]$PackageVersion
    )
    try{
        if($PackageVersion)
        {
            Install-Package $PackageName -ProjectName $ModuleName $PackageVersion
        }
        else {
            Install-Package $PackageName -ProjectName $ModuleName
        }
        Write-StepInfo -Tag $PackageName -Message "Package has been installed"
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        #throw
    }
}

##############################
#.SYNOPSIS
# For the given project (ModuleName) performs some basic setup of the project for use.
# Elements that are configured for the project are:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.1
#   * NuGet Install of - Microsoft.AspNet.MVC
#   * NuGet Install of - Sitecore.Kernel.NoReferences
#   * NuGet Install of - Sitecore.Mvc.NoReferences
#   * NuGet Install of - Sitecore.Logging.NoReferences
#   * NuGet Install of -  Microsoft.Extensions.DependencyInjection.Abstractions version 1.0.0
#   * NUGet Install of - Galss.Mapper.Sc if required (default is NOT to install)
#   * Set all Reference DLLs to be Copy Local = False
#   
#.DESCRIPTION
# For the given project (ModuleName) performs some basic setup of the project for use.
# Elements that are configured for the project are:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.1
#   * NuGet Install of - Microsoft.AspNet.MVC
#   * NuGet Install of - Sitecore.Kernel.NoReferences
#   * NuGet Install of - Sitecore.Mvc.NoReferences
#   * NuGet Install of - Sitecore.Logging.NoReferences
#   * NuGet Install of -  Microsoft.Extensions.DependencyInjection.Abstractions version 1.0.0
#   * NUGet Install of - Galss.Mapper.Sc if required (default is NOT to install)
#   * Set all Reference DLLs to be Copy Local = False
#   
#.PARAMETER ModuleName
# Name of the project to be updated
#
# REQUIRED
# 
#.
#.PARAMETER SitecoreVersion
# Optional parameter, that identifies which version of Sitecore NuGet Packages will be installed.
# If no value is provided the latest version will be installed.
#
# Parameter validation will force proper formatt of #.#.#### for example 9.0.171219
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$
#
# OPTIONAL
#
#.PARAMETER DotNETTargetFramework
# Enter the version of the .NET Framwork that the project should build as.
#
# DEFAULT VALUE: 262662 - representing 4.6.2
# For reference: 262407 - representing 4.7.1
#
# OPTIONAL
# 
#.PARAMETER IncludeGlassMapper
# Include the switch if Glass.Mapper.Sc should be installed from NuGet
#
# DEFAULT VALUE: false
#
# OPTIONAL
#
#.EXAMPLE
# > Set-ModuleFiles -ModuleName 'Coffeehouse.Feature.CouponCode'
# 
# > Set-ModuleFiles -ModuleName 'Coffeehouse.Feature.CouponCode' -SitecoreVersion '8.2.161115'
#
# > Set-ModuleFiles -ModuleName 'Coffeehouse.Feature.CouponCode' -SitecoreVersion '8.2.161115' -DotNETTargetFramework '25023'
#
# > Set-ModuleFiles -ModuleName 'Coffeehouse.Feature.CouponCode' -IncludeGlassMapper
#.NOTES
# Private Method
##############################
function Set-ModuleFiles{
	Param(
		[Parameter(Position=0, Mandatory=$True)]
        [string]$ModuleName,
        [Parameter(Position=1, Mandatory=$false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$")]
        [string] $SitecoreVersion,
        [Parameter(Position=2, Mandatory=$false)]
        [string] $DotNETTargetFramework='262662',
		[Parameter(Mandatory=$false)]
        [switch] $IncludeGlassMapper
	)
    try
    {
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Save Solution to ensure clean start"
        Save-VisualStudioSolution

        #Get Moduel Project
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Get Project from Solution"
        $moduleProj = Get-Project $ModuleName
        if($moduleProj -eq $null){
            Write-Error -Tag "Set Module Files: $ModuleName" -Message "Project named $ModuleName not found" 
            Write-Error -Tag "Set Module Files: $ModuleName" -Message "no file setup can happen"
            return
        }

        #Get Web.config and set to BUILD ACTION = NONE
        $webConfig = $moduleProj.ProjectItems| Where-Object{$_.Name -eq 'Web.config'}
        if($webConfig -ne $null){
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Web.config found, setting build action"
            ($webConfig.Properties | Where-Object{$_.Name -eq 'BuildAction'}).Value = 0
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Save Solution"
            Save-VisualStudioSolution
        }

        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Project named $ModuleName not found" -ErrorAction
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "no file setup can happen" -ErrorAction
            return
        }
        # #Set Target Framework to 4.7.1
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Set Target Framework to $DotNETTargetFramework"
        $moduleProj.Properties["TargetFramework"].Value = $DotNETTargetFramework
       
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        ##Need to reload object for additional work.
        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Project named $ModuleName not found" -ErrorAction
            Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "no file setup can happen" -ErrorAction
            return
        }
        #Install MVC
        Add-PackageToModule -ModuleName $ModuleName -PackageName 'Microsoft.AspNet.Mvc'

        #Install Sitecore.Kernel.NoReference
        Add-PackageToModule -ModuleName $ModuleName -PackageName 'Sitecore.Kernel.NoReferences' -PackageVersion $SitecoreVersion

        #Install Sitecore.MVC.NoReference
        Add-PackageToModule -ModuleName $ModuleName -PackageName 'Sitecore.Mvc.NoReferences' -PackageVersion $SitecoreVersion

        #Install Sitecore.Logging.NoReference
        Add-PackageToModule -ModuleName $ModuleName -PackageName 'Sitecore.Logging.NoReferences' -PackageVersion $SitecoreVersion

        #Install Microsoft.Extensions.DependencyInjection
        Add-PackageToModule -ModuleName $ModuleName -PackageName 'Microsoft.Extensions.DependencyInjection' -PackageVersion '1.0.0'

        #Install Glass.Mapper.Sc.Core if required
        if($IncludeGlassMapper)
        {
            Add-PackageToModule -ModuleName $ModuleName -PackageName 'Glass.Mapper.Sc.Core'	
        }

        #Set All Assemblies as CopyLocal = False
        Write-StepInfo -Tag $ModuleName -Message "Setting references to Copy Local = False"
        $moduleProj.Object.References|ForEach-Object{try{$_.CopyLocal=$false}catch{Write-host "error for: $($_.Name)"}}
        
        #SAVE PROJECT AFTER CHANGES
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Saving the Module"
        $moduleProj.Save()

        #SAVE SOLUTION - not sure if it is needed but just feels right to do a save after this work.
        Write-StepInfo -Tag "Set Module Files: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Adds a Module specific config file to App_Config -> Include -> $Layer
# The config is then updated to be a proper Sitecore patch file with the Dependecy Registar already added.
#
#.DESCRIPTION
# Adds a Module specific config file to App_Config -> Include -> $Layer
# The config is then updated to be a proper Sitecore patch file with the Dependecy Registar already added.
#
#.PARAMETER ModuleName
# Name of the project (module) to be add the config file to 
#
# REQUIRED
#
#.PARAMETER Layer
# Type of project (module), should follow the naming convention of the solution.
# Default Helix naming would be Feature, Foundation, Project
#
# REQUIRED
#
#.PARAMETER TemplatePath
# Path to the configuration template to be used.
# In most instances this will be generated from a previous step call to Get-VisualStudioTemplate
#
# REQUIRED
#
#.EXAMPLE
# > Add-ModuleConfigFile -ModuleName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -TemplatePath "C:\Programs\VS\webconfig.vstemplate"
#
#.NOTES
# Private Method
##############################
function Add-ModuleConfigFile{
    Param(
		[Parameter(Position=0, Mandatory=$True)]
		[string]$ModuleName,
		[Parameter(Position=1, Mandatory=$True)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,		
        [Parameter(Position=2, Mandatory=$True)]
		[string]$TemplatePath
    )
    try{
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Begin"

        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Project named $ModuleName not found" 
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "no file setup can happen" 
            return
        }

        #ADD - App_Config -> Include -> $Layer
        $appconfig_Folder = Get-ProjectItem -ProjectItem $moduleProj -ItemName 'App_Config'
        if($appconfig_Folder -eq $null)
        {
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "App_Config does not exist, creating"
            $appconfig_Folder =$moduleProj.ProjectItems.AddFolder("App_Config");
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Creating 'include' folder"
            $include_Folder = $appconfig_Folder.ProjectItems.AddFolder("Include");  
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Creating '$ModuleName' folder"      
            $tempFolder = $include_Folder.ProjectItems.AddFolder($Layer);
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "creating module config file"
            $tempFolder.ProjectItems.AddFromTemplate($TemplatePath, $ModuleName+".config")
        }
        else {
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "App_Config already exists"
            $include_Folder = Get-ProjectItem -ProjectItem $moduleProj -ItemName 'Include'
            if($include_Folder -eq $null)
            {
                Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Creating 'include' folder"
                $include_Folder = $appconfig_Folder.ProjectItems.AddFolder("Include");  
                Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Creating '$ModuleName' folder"      
                $tempFolder = $include_Folder.ProjectItems.AddFolder($Layer);
                Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "creating module config file"
                $tempFolder.ProjectItems.AddFromTemplate($TemplatePath, $ModuleName+".config")
            }
        }
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Save project"
        $moduleProj.Save()
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Project named $ModuleName not found" 
            Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "no file setup can happen" 
            return
        }


        #EDIT CONFIG    
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Begin update of $ModuleName.config"
        $ModuleFileSystemPath = Split-Path $moduleProj.FullName
        $configFile = "{0}\App_Config\Include\{1}\{2}.config" -f $ModuleFileSystemPath, $Layer, $ModuleName   
        [xml] $config =Get-Content -Path $configFile

        ##Set Sitecore Patch Attribute
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Updating config to support Sitecore patch"
        $config.configuration.SetAttribute("xmlns:patch", "http://www.sitecore.net/xmlconfig/")
        ##Add Sitecore Node
        $sitecorenode = $config.CreateElement("sitecore")
        $servicesnode = $config.CreateElement("services")
        $configuratornode = $config.CreateElement("configurator")
        $tempValue  = "{0}.DI.RegisterDependencies, {0}" -f $ModuleName
        $configuratornode.SetAttribute("type", $tempValue)
        $servicesnode.AppendChild($configuratornode)
        $sitecorenode.AppendChild($servicesnode)
        $config.configuration.AppendChild($sitecorenode)

        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Saving updated config file"
        $config.Save($configFile)

        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Saving module (project)"
        $moduleProj.Save()
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        Write-StepInfo -Tag "Add Module Config Files: $ModuleName" -Message "Module specific config update complete"
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Adds default folders to a Helix based project for 
# * DI
# * Views
# * Views\$ModuleName
# * Repositories
# * Constants
# * Controllers
# * Models
#
# Folders are created via a call to Add-FolderToProjectItem, which creates the folder both in the solution and on the file system
#
#.DESCRIPTION
# Adds default folders to a Helix based project for 
# * DI
# * Views
# * Views\$ModuleName
# * Repositories
# * Constants
# * Controllers
# * Models
#
# Folders are created via a call to Add-FolderToProjectItem, which creates the folder both in the solution and on the file system
#
#.PARAMETER ModuleName
# Name of the project (module) being updated
#
#.EXAMPLE
# > Add-ModuleDefaultFolders -ModuleName 'Coffeehouse.Feature.CouponCode'
#
#.NOTES
#General notes
##############################
function Add-ModuleDefaultFolders{
    Param(
        [Parameter(Position=0, Mandatory=$True)]
        [string]$ModuleName
    )
    try{
        Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Begin"

        Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Project named $ModuleName not found" 
            Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "no setup can happen" 
            return
        }
        #Create Folders
        ## DI Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'DI'

        ## Views Folder
        $viewFolder = Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Views'
        Add-FolderToProjectItem -ProjectItem $viewFolder -FolderName $ModuleName
        
        ## Repositories Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Repositories'
        ## Constants Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Constants'
        ## Models Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Models'
        ## Controllers Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Controllers'
        
        Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Saving module (project)"
        $moduleProj.Save()
        Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        Write-StepInfo -Tag "Add Module Default Folders: $ModuleName" -Message "Completed"
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Creates a RegisterContainer.cs file inside the folder 'DI' with the following logic
#
#using Microsoft.Extensions.DependencyInjection;
#using Sitecore.DependencyInjection;
#
#namespace {0}.DI
#{
#	public class RegisterContainer : IServicesConfigurator
#	{
#		public void Configure(IServiceCollection serviceCollection)
#		{
#			//serviceCollection.AddTransient<ContentController>();
#			//serviceCollection.AddTransient<IAccountRepository, AccountRepository>();            
#		}
#	}
#}
#
#.DESCRIPTION
# Creates a RegisterContainer.cs file inside the folder 'DI'
#
#.PARAMETER ModuleName
# Name of project (module) that the register container shoudl be created for
#
# REQUIRED
#
#.PARAMETER ClassTemplatePath
# Path to the C# class template
#
# REQUIRED
#
#.EXAMPLE
# > Add-RegisterContainerClass 'Coffeehouse.Feature.CouponCode' 'C:\Programs\VS\class.vstemplate'
#
#.NOTES
#Private Method
##############################
function Add-RegisterContainerClass{
    Param(
        [Parameter(Position=0, Mandatory=$True)]
        [string]$ModuleName,
        [Parameter(Position=1, Mandatory=$True)]
        [string]$ClassTemplatePath
    )
    try{
        Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Begin"

        Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ModuleName
        if($moduleProj -eq $null){
            Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Project named $ModuleName not found" 
            Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "no setup can happen" 
            return
        }
       
        $DIFolder = Get-ProjectItem -ProjectItem $moduleProj -ItemName 'DI'
        if($DIFolder -ne $null){
            Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Creating RegisterContainer.cs in solution"
            $ModuleFileSystemPath = Split-Path $moduleProj.FullName
            $DIFolder.ProjectItems.AddFromTemplate($ClassTemplatePath,"RegisterContainer.cs")
            $moduleProj.Save()

            Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Save Solution"
            Save-VisualStudioSolution

            Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Begin content update"
            $RegisterTemplate=@"
using Microsoft.Extensions.DependencyInjection;
using Sitecore.DependencyInjection;

namespace MODULENAME.DI
{
	public class RegisterContainer : IServicesConfigurator
	{
		public void Configure(IServiceCollection serviceCollection)
		{
			//serviceCollection.AddTransient<ContentController>();
			//serviceCollection.AddTransient<IAccountRepository, AccountRepository>();            
		}
	}
}
"@ 
$rt = $RegisterTemplate.Replace("MODULENAME", $ModuleName)
Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Updating contents of RegisterContainer.cs"
        Set-Content -Path $($ModuleFileSystemPath+'\DI\RegisterContainer.cs') -Value $rt
        Write-StepInfo -Tag "Add Register Container Class: $ModuleName" -Message "Content update for $($ModuleFileSystemPath+'\DI\RegisterContainer.cs')"
        }
    }
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}


##############################
#.SYNOPSIS
# Creates a new serialziation project within the solution for a given module
#
# Logic currently only supports TDS.
#
#.DESCRIPTION
# Creates a new serialziation project within the solution for a given module
#
#.PARAMETER ModuleName
# Name of the project (or module being added)
#
# REQUIRED
#
#.PARAMETER Layer
# Type of module (normally Feature, Foundation, or Project).
# This should match similar values as the folder structure has been defined for seperateion.
#
# REQUIRED
#
#.PARAMETER SourceCodeRootPath
# Full path to the parent locaiton of Module Type folders
# 
# ex: 'C:\Code\MySamples\Helix.Demo.Solution\src'
#
# REQUIRED
#
#.PARAMETER IsTDSSerialization
# switch when included will generate a TDS project with the name: $ModuleName.TDS.Master
#
# OPTIONAL
#
#.EXAMPLE
# Currently this does nothing:
# > Add-SerializationProject -ModuleName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -SourceCodeRootPath 'C:\Code\Coffeehouse\src'
#
# Creates TDS project
# > Add-SerializationProject -ModuleName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -SourceCodeRootPath 'C:\Code\Coffeehouse\src' -IsTDSSerialization
#
#.NOTES
# Private Method
##############################
function Add-SerializationProject{
    Param(
        [Parameter(Position=0, Mandatory=$True)]
        [string]$ModuleName,
        [Parameter(Position=1, Mandatory=$True)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,
        [Parameter(Position=2, Mandatory=$True)]
        [string]$SourceCodeRootPath,
        [Parameter(Position=3, Mandatory=$false)]
        [string]$ProjectTemplateName = "TDS Project.vstemplate",
        [Parameter(Position=4, Mandatory=$false)]
        [string]$SourceCodeFolderName='tds',
        [Parameter(Mandatory=$false)]
        [switch]$IsTDSSerialization
        )        
    try
    {    
        Write-StepInfo -Tag "Add Serializaton Project: $ModuleName" -Message "Begin"

        Write-StepInfo -Tag "Add Serializaton Project: $ModuleName" -Message "Save Solution"
        Save-VisualStudioSolution
        
        Write-StepInfo -Tag "Add Serializaton Project: $ModuleName" -Message "Retreive Layer Folder: $Layer"
        $layerFolder = Get-SolutionFolder $Layer
        $sp = Get-ProjectItem $layerFolder $ModuleName
        if(-NOT $sp){
            Write-StepInfo -Tag "Add Serializaton Project: $ModuleName" -Message "Solution Folder for Module Not Found"
            Write-StepInfo -Tag "Add Serializaton Project: $ModuleName" -Message "No actions taken"
            return
        }
        if($IsTDSSerialization)
        {
            $tdsProjectName = "$ModuleName.TDS.Master"
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Add TDS Serialization Project"
            #Check that the project does not exist on the file system
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path format: {0}\{1}\{2}\{3}\{4}"
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path Part 0: $SourceCodeRootPath"
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path Part 1: $Layer"
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path Part 2: $ModuleName"   
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path Part 3: $SourceCodeFolderName"
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Path Part 4: $tdsProjectName"   
            $modulePath = "{0}\{1}\{2}\{3}\{4}" -f $SourceCodeRootPath, $Layer, $ModuleName, $SourceCodeFolderName, $tdsProjectName
            Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "Final Path: $modulePath"   
            if(Test-Path $modulePath){
                Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "$modulePath exists on the file system"
                Write-StepInfo -Tag "Add Serializaton Project: $tdsProjectName" -Message "$tdsProjectName will not be created."
                return
            }

            Write-StepInfo -Tag "Add Serializaton Project:$tdsProjectName" -Message "Retrieve TDS Project Template - $ProjectTemplateName"
            $projecttemplate = Get-VisualStudioTemplate -TemplateName $ProjectTemplateName
            Write-StepInfo -Tag "Add Serializaton Project:$tdsProjectName" -Message "Template Location: $projecttemplate"
            $sp.SubProject.Object.AddFromTemplate($projecttemplate, $modulePath, $tdsProjectName)

            Write-StepInfo -Tag "Add Serializaton Project:$tdsProjectName" -Message "Saving Solution after project add"
            Save-VisualStudioSolution
            Write-StepInfo -Tag "Add Serializaton Project:$tdsProjectName" -Message "TDS Project created at $modulePath"
        }
            #TODO - setup for Unicorn serialization
           # else {
           #    $slnFolderObj.AddFromTemplate($ModuleProjectTemplate, $SourceCodeRootPath + '\'+ $Layer + '\'+$ModuleName + '\' + $SerializationFolderName_Unicorn, $ModuleName)
           # }       		
	}
    catch {
        # Write the error information then rethrow
        # We need the error information in the log
        # The rethrow is for any calling script
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

###############
#PUBLIC TASKS
# written in SIF manner
###############

##############################
#.SYNOPSIS
# Writes text to the screen in the format:
# [$Tag] $Message
#
# If $TextColor is set the foreground color of the message will be shown as this value
#
#.DESCRIPTION
# Writes text to the screen in the format:
# [$Tag] $Message
#
# If $TextColor is set the foreground color of the message will be shown as this value
#
#.PARAMETER Message
# Longer text message for writing to screen
#
# REQUIRED
#
#.PARAMETER Tag
# Identifier to help visually understand what the message relates to.
#
# REQUIRED 
#
#.PARAMETER TextColor
# Option to change the text color that is displayed.
# Default: Gray
#
# OPTIONAL
#
#.EXAMPLE
# > Write-StepInfo -TaskInfo "Step 1" -Message "Hello World loading."
# > [Step 1] Hello World loading.
#
#.NOTES
# Public Method
##############################
function Write-StepInfo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','')]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Tag,    
        [Parameter(Position=1, Mandatory=$true)]
        [object]$Message,        
        [Parameter(Mandatory=$false)]
        [string]$TextColor='Gray' 
    )

    $value = "[$Tag] $Message"

    if($PSBoundParameters.ContainsKey('Verbose')) {
        Write-Verbose -Message $value -ForegroundColor $TextColor
    } else {
        Write-Host $value -ForegroundColor $TextColor
    }
}

##############################
#.SYNOPSIS
# Writes a message in the following formatt to the screen, useful for delinating major steps taken. This will span the entire screen width.
#   [ ------------- $TASKNAME : $TASKTYPE ------------]
#
#.DESCRIPTION
# Writes a message in the following formatt to the screen, useful for delinating major steps taken. This will span the entire screen width.
#   [ ------------- $TASKNAME : $TASKTYPE ------------]
#
#.PARAMETER TaskName
# Name/Short description of the task/action being performed
#
# REQUIRED
#
#.PARAMETER TaskType
# Categorization value, to help indentify type of task/action being performed.
#
# REQUIRED
#
#.PARAMETER TextColor
# Foreground color of the text
# Default is 'Green'
# 
# OPTIONAL
#
#.EXAMPLE
# > Write-StepHeader -TaskName "Create the World" -TaskType "Creation"
#
#.NOTES
# Public Method
##############################
function Write-StepHeader {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','')]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [string]$TaskType,
        [Parameter(Mandatory=$false)]
        [string]$TextColor='Green'
    )

    function StringFormat {
        param(
            [int]$length,
            [string]$value,
            [string]$prefix = '',
            [string]$postfix = '',
            [switch]$padright
        )

        # wraps string in spaces so we reduce length by two
        $length = $length - 2 #- $postfix.Length - $prefix.Length
        if($value.Length -gt $length){
            # Reduce to length - 4 for elipsis
            $value = $value.Substring(0, $length - 4) + '...'
        }

        $value = " $value "
        if($padright){
            $value = $value.PadRight($length, '-')
        } else {
            $value = $value.PadLeft($length, '-')
        }

        return $prefix + $value + $postfix
    }

    $actualWidth = (Get-Host).UI.RawUI.BufferSize.Width
    $width = $actualWidth - ($actualWidth % 2)
    $half = $width / 2

    $leftString = StringFormat -length $half -value $TaskName -prefix '[' -postfix ':'
    $rightString = StringFormat -length $half -value $TaskType -postfix ']' -padright

    $message = ($leftString + $rightString)
    Write-Host ''
    Write-Host $message -ForegroundColor $TextColor
}



##############################
#.SYNOPSIS
# Performs a number of differnt steps in setting up and configuring the Module Web project.
#
# STEP 1: Configures the following for the project:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.1
#   * NuGet Install of - Microsoft.AspNet.MVC
#   * NuGet Install of - Sitecore.Kernel.NoReferences
#   * NuGet Install of - Sitecore.Mvc.NoReferences
#   * NuGet Install of - Sitecore.Logging.NoReferences
#   * NuGet Install of -  Microsoft.Extensions.DependencyInjection.Abstractions version 1.0.0
#   * NUGet Install of - Galss.Mapper.Sc if required (default is NOT to install)
#   * Set all Reference DLLs to be Copy Local = False
#
# STEP 2: Adds a Module specific config file to App_Config -> Include -> $Layer, which is then configured for Dependecny Register class
#
# STEP 3: Adds default folders to a Helix based project for 
#   * DI
#   * Views
#   * Views\$ModuleName
#   * Repositories
#   * Constants
#   * Controllers
#   * Models
#
# STEP 4: Creates a RegisterContainer.cs file inside the folder 'DI' with the default logic
#
#.DESCRIPTION
# Performs a number of differnt steps in setting up and configuring the Module Web project.
#
# STEP 1: Configures the following for the project:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.1
#   * NuGet Install of - Microsoft.AspNet.MVC
#   * NuGet Install of - Sitecore.Kernel.NoReferences
#   * NuGet Install of - Sitecore.Mvc.NoReferences
#   * NuGet Install of - Sitecore.Logging.NoReferences
#   * NuGet Install of -  Microsoft.Extensions.DependencyInjection.Abstractions version 1.0.0
#   * NUGet Install of - Galss.Mapper.Sc if required (default is NOT to install)
#   * Set all Reference DLLs to be Copy Local = False
#
# STEP 2: Adds a Module specific config file to App_Config -> Include -> $Layer, which is then configured for Dependecny Register class
#
# STEP 3: Adds default folders to a Helix based project for 
#   * DI
#   * Views
#   * Views\$ModuleName
#   * Repositories
#   * Constants
#   * Controllers
#   * Models
#
# STEP 4: Creates a RegisterContainer.cs file inside the folder 'DI' with the default logic
#
#.PARAMETER ModuleName
# Name of the Module the serialization project is for.
#
# REQUIRED
#
#.PARAMETER Layer
# Which layer will the module be created under.
# Parameter validation will limit to "Feature", "Foundation", or "Project"
#
# REQUIRED
#
#.PARAMETER SitecoreVersion
# Optional parameter, that identifies which version of Sitecore NuGet Packages will be installed.
# If no value is provided the latest version will be installed.
#
# Parameter validation will force proper formatt of #.#.#### for example 9.0.171219
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$
#
# OPTIONAL
#
#.PARAMETER TemplateName
# Name with extension of the Visual Studio Template that is used to create a Class file (ex: .cs) type file.
#
# DEFAULT: Class.vstemplate
#
# OPTIONAL
#
#.PARAMETER TemplateFilter
# String representing a filter for the path the above TemplateName would exist at. This is used to locate the correct template, when the name is re-used
#
# DEFAULT: '*Web\CSharp\*'
#
# OPTIONAL
#
#.PARAMETER UseGlass
# Switch (flag) that when included indicates the Glass.Mapper.Sc NuGet Packages should be installed
#
# OPTIONAL
#
#.EXAMPLE
# > Invoke-ModuleFileSetup "Coffeehouse.Featuer.ShoppingHistory" "Feature" -UseGlass
#
# > Invoke-ModuleFileSetup -ModuleName "Coffeehouse.Featuer.ShoppingHistory" -Layer "Feature" -UseGlass
#
#.NOTES
#General notes
##############################
function Invoke-ModuleFileSetup{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Position=0, Mandatory=$true)]
        [string]$ModuleName,
        [parameter(Position=1, Mandatory=$true)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,        
        [parameter(Position=2,Mandatory=$false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$")]      
        [string]$SitecoreVersion,
        [parameter(Position=3,Mandatory=$false)]        
        [string]$TemplateName ="Class.vstemplate",
        [parameter(Position=4,Mandatory=$false)]        
        [string]$TemplateFilter ='*Web\CSharp\*',
        [parameter(Mandatory=$false)]
        [switch]$UseGlass
    )

    PROCESS
    {
        Write-StepHeader "$ModuleName - File Setup"  -TaskType "Module"
        if($pscmdlet.ShouldProcess("$ModuleName", "Begin file setup of new Module")){
            
            ##STEP 1: Install NuGet Packages, Set References to not copy
            if($UseGlass){
                Write-StepInfo -Tag "Setup: $ModuleName" -Message "1. Set Module Files with Glass Mapper"
                Set-ModuleFiles -ModuleName $ModuleName -IncludeGlassMapper -SitecoreVersion $SitecoreVersion
            }
            else {
                Write-StepInfo -Tag "Setup: $ModuleName" -Message "1. Set Module Files"
                Set-ModuleFiles -ModuleName $ModuleName -SitecoreVersion $SitecoreVersion
            }

            ##STEP 2: Added Module Config File
            $webConfigTemplate = Get-VisualStudioTemplate -TemplateName 'WebConfig.vstemplate' -FilterValue '*CSharp\Web*'
            Write-StepInfo -Tag "Setup: $ModuleName" -Message "2. Create Module Config File"
            Add-ModuleConfigFile -ModuleName $ModuleName -Layer $Layer -TemplatePath $webConfigTemplate

            ##STEP 3: Created Default folders: DI, Views, Repositories, Constants, Controllers, Models
            Write-StepInfo -Tag "Setup: $ModuleName" -Message "3. Begin Module Default File Creation (DI, Views, Repositories, Constants, Controllers, Models"
            Add-ModuleDefaultFolders -ModuleName $ModuleName

            ##STEP 4: 
            Write-StepInfo -Tag "Setup: $ModuleName" -Message "4. Create and update RegisterContainer.cs"
            $classTemplatePath = Get-VisualStudioTemplate -TemplateName $TemplateName -FilterValue $TemplateFilter
            Add-RegisterContainerClass -ModuleName $ModuleName -ClassTemplatePath $classTemplatePath
        }
    }
}

##############################
#.SYNOPSIS
# Creates a serialization project for the named module
#
# IMPORTANT: Script only creates TDS projects currently that are always named 'Master'
#
#.DESCRIPTION
# Creates a serialization project for the named module
#
# IMPORTANT: Script only creates TDS projects currently that are always named 'Master'
#
#.PARAMETER ModuleName
# Name of the Module the serialization project is for.
# If for TDS, the project will be named $ModuleName.TDS.Master
#
# REQUIRED
#
#.PARAMETER Layer
# Which layer will the module be created under.
# Parameter validation will limit to "Feature", "Foundation", or "Project"
#
# REQUIRED
#
#.PARAMETER UseTDS
# Switch (flag) parameter, only include if you wish to have a TDS Project created for the module
#
# OPTIONAL
#
#.PARAMETER UseUnicorn
# Switch (flag) parameter, only include if you wish to have a Unicorn Serailization Project created for the module
#
# OPTIONAL
#
# IMPORTANT: This parameter currently does nothing, and is included for future updates
#
#.EXAMPLE
# > Invoke-SerializationProject -ModuleName "Coffeehouse.Foundation.Search" -Layer "Foundation" -UseTDS
#
# > Invoke-SerializationProject "Coffeehouse.Foundation.Search" "Foundation" -UseTDS
#
#.NOTES
# UseUnicorn switch currently does nothing, this is for future use.
##############################
function Invoke-SerializationProject{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Position=0,Mandatory=$true)]
        [string]$ModuleName,
        [parameter(Position=1,Mandatory=$true)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,
        [parameter(Mandatory=$false)]
        [switch]$UseTDS,
        [parameter(Mandatory=$false)]
        [switch]$UseUnicorn
    )

    PROCESS
    { 
        Write-StepHeader "$ModuleName - Create Serialization Project" -TaskType "Module"              
        if($pscmdlet.ShouldProcess("$ModuleName", "Begin Serialziation Project Creation")){
            if($UseTDS){
            Add-SerializationProject -ModuleName $ModuleName -Layer $Layer -SourceCodeRootPath $(Invoke-SolutionRootPath) -ProjectTemplateName "TDS Project.vstemplate" -SourceCodeFolderName "tds" -IsTDSSerialization
            }
            else{
                Write-StepInfo -Tag "Serialization" -Message "Unicorn serializaiton not yet implemented, no setup taken."
            }
        }
    }
}

##############################
#.SYNOPSIS
# Retrieves the active solutions path to its 'src' folder
#
#.DESCRIPTION
# Retrieves the active solutions path to its 'src' folder
#
#.PARAMETER SourceFolderName
# Folder on the file system that source code will be nested under.
# Default: src
#
# OPTIONAL
#
#.EXAMPLE
# > $rootPath = Invoke-SolutionRootPath
# > $rootPath
# > C:\Code\Coffeehouse.Demo.SC9\src
#
#.NOTES
# Simple utility function to ensure you always have the same 'src' path for project and file creation.
##############################
function Invoke-SolutionRootPath{
    param(
        [parameter(Position=0, Mandatory=$false)]
        [string]$SourceFolderName = 'src'
       
    )
    $basePath = Split-Path $dte.Solution.FullName
    return $basePath +'\' + $SourceFolderName
}

##############################
#.SYNOPSIS
# Creates a new Empty Web Application Project namaed $ModuleName, under the $Layer folder 
#
# IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:
#       > $dte.Solution.FullName
#
# If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project
#
#.DESCRIPTION
# Creates a new Empty Web Application Project namaed $ModuleName, under the $Layer folder 
#
# IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:
#       > $dte.Solution.FullName
#
# If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project
#
#.PARAMETER ModuleName
# Name of the Module, will be used for File System Folder as well as web application project name (and namespace)
#
# REQUIRED
#
#.PARAMETER Layer
# Which layer will the module be created under.
# Parameter validation will limit to "Feature", "Foundation", or "Project"
#
# REQUIRED
#
#.EXAMPLE
# > Invoke-CreateModule -ModuleName "Coffeehouse.Foundation.Search" -Layer "Foundation"
#
# > Invoke-CreateModule "Coffeehouse.Foundation.Search" "Foundation"
#
#.NOTES
#General notes
##############################
function Invoke-CreateModule{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Position=0, Mandatory=$true)]
        [string]$ModuleName,
        [parameter(Position=1, Mandatory=$true)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer
    )

    PROCESS
    { 
        Write-StepHeader "$Layer - $ModuleName - Create New Module" -TaskType "Module"
        if($pscmdlet.ShouldProcess("$ModuleName", "Begin Project Creation")){
            $templatePath = Get-VisualStudioTemplate -TemplateName 'EmptyWebApplicationProject40.vstemplate' -FilterValue "*\CSharp\Web\*"        
            Write-StepInfo -Tag "$ModuleName" -Message "Project Template: $templatePath"
            $slnPath = Invoke-SolutionRootPath
            Add-Module -ModuleName $ModuleName -Layer $Layer -ModuleProjectTemplate $templatePath -SourceCodeRootPath $slnPath
        }
    }
}


##############################
#.SYNOPSIS
# Create and setup a new module project into any layer with the option for assocated serialization projects/folders to be created.
#
# IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:
#       > $dte.Solution.FullName
#
# If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project
#
#.DESCRIPTION
# Create and setup a new module project into any layer with the option for assocated serialization projects/folders to be created.
#
# IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:
#       > $dte.Solution.FullName
#
# If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project
#
#.PARAMETER ModuleName
# Name of the Module, will be used for File System Folder as well as web application project name (and namespace)
#
# REQUIRED
#
#.PARAMETER Layer
# Which layer will the module be created under.
# Parameter validation will limit to "Feature", "Foundation", or "Project"
#
# REQUIRED
#
#.PARAMETER SitecoreVersion
# Optional parameter, that identifies which version of Sitecore NuGet Packages will be installed.
# If no value is provided the latest version will be installed.
#
# Parameter validation will force proper formatt of #.#.#### for example 9.0.171219
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$
#
# OPTIONAL
#
#.PARAMETER UseGlass
# Switch (flag) parameter, only include if you wish to have Glass.Mapper.Sc related NuGet packages installed.
# Only the latest version will be installed.
#
# OPTIONAL
#
#.PARAMETER UseTDS
# Switch (flag) parameter, only include if you wish to have a TDS Project created for the module
#
# OPTIONAL
#
#.PARAMETER UseUnicorn
# Switch (flag) parameter, only include if you wish to have a Unicorn Serailization Project created for the module
#
# OPTIONAL
#
# IMPORTANT: This parameter currently does nothing, and is included for future updates
#
#.EXAMPLE
# > Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -UseGlass -UseTDS
#
# > Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121"
#
# > Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseGlass -UseTDS
#
# > Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseGlass -UseUnicorn
#
# > Invoke-NewModule -ModuleName "Coffeehouse.Demo.Feature.Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseTDS
#
#.NOTES
# n/a
##############################
function Invoke-NewModule{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Position=0, Mandatory=$true)]
        [string]$ModuleName,        
        [parameter(Position=1,Mandatory=$true)]
        [ValidateSet("Feature","Foundation", "Project")]
        [string]$Layer,
        [parameter(Position=2,Mandatory=$false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$")]
        [string]$SitecoreVersion,
        [parameter(Mandatory=$false)]
        [switch]$UseGlass,
        [parameter(Mandatory=$false)]
        [switch]$UseTDS,
        [parameter(Mandatory=$false)]
        [switch]$UseUnicorn
    )

    PROCESS
    { 
        Write-StepHeader "Creates and Populates a Module Project" -TaskType "Module"
        Write-StepInfo -Tag "Module" -Message "Current solution is $($dte.Solution.FullName)"
        if($pscmdlet.ShouldProcess("$ModuleName", "Begin Module Creation and Population")){
            Save-VisualStudioSolution
            Write-StepInfo -Tag "Module Create" -Message "Step 1: Create Module Project"
            Invoke-CreateModule -ModuleName $ModuleName -Layer $Layer
            Save-VisualStudioSolution
            Write-StepInfo -Tag "Module Create" -Message "Step 2: Setup Files"
            Invoke-ModuleFileSetup $ModuleName $Layer -UseGlass:$UseGlass -SitecoreVersion $SitecoreVersion
            Save-VisualStudioSolution
            if($UseTDS)
            {
                Write-StepInfo -Tag "Module Create" -Message "Step 3: Setup Serialization"
                Invoke-SerializationProject -ModuleName $ModuleName -Layer $Layer -UseTDS:$UseTDS
                Save-VisualStudioSolution
            }
            elseif($UseUnicorn)
            {
                Write-StepInfo -Tag "Module Create" -Message "Step 3: Unicorn selected as serializtion option, no action taken at this time."
                Write-StepInfo -Tag "Module Create" -Message "Step 3: No Serialization Setup"
            } 
            else 
            {
                Write-StepInfo -Tag "Module Create" -Message "Step 3: No Serialization Setup Requested"
            }
            Write-StepInfo "Create and Populate: $ModuleName" -Message "New Module $ModuleName Ready for Sitecore"
        }
    }
}

###############################
#.SYNOPSIS
# Creates a new Visual Studio Solution and adds basic Helix solution and file system folders.
#
# File Systme will look like the following
# - Directory Path
# -- Solution Name
# -- SolutionName.sln
# -- lib
# -- src
# --- __Documents
# --- __Scripts
# --- Feature
# --- Foundation
# --- Project
#
#.DESCRIPTION
# Creates a new Visual Studio Solution and adds basic Helix solution and file system folders.
#
# File Systme will look like the following
# - Directory Path
# -- Solution Name
# -- SolutionName.sln
# -- lib
# -- src
# --- __Documents
# --- __Scripts
# --- Feature
# --- Foundation
# --- Project
#
#.PARAMETER SolutionPath
# Path where the Solution will be saved to.
#
#.PARAMETER SolutionName
# Name of the Solution. 
# Folder by this name will be created at $SolutionPath
#
#.EXAMPLE
# > Invoke-VisualStudioSolution -SolutionPath "C:\Code" -SolutionName "Coffeehouse.Demo.SC9"
#
# > Invoke-VisualStudioSolution "C:\Code" "Coffeehouse.Demo.SC9"
#
#.NOTES
# n/a
##############################
function Invoke-ViusalStudioSolution{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$SolutionPath,
        [parameter(Mandatory=$true)]
        [string]$SolutionName
    )

    PROCESS
    {
        Write-StepHeader "$SolutionName - Create a new solution" -TaskType "Solution"
            
        if($pscmdlet.ShouldProcess("$SolutionName", "Begin create of new Visual Studio Soltion")){
            Write-StepInfo -Message "$SolutionName" -Tag "Solution Being created"
            $slnlocation = New-VisualStudioSolution -SolutionName $SolutionName -DirectoryPath $SolutionPath                        
            Write-StepInfo -Message "$SolutionName" -Tag "Solution created at: $slnlocation"
            Write-StepInfo -Message "$SolutionName" -Tag "Solution is ready for Sitecore magic"
        }
    }
}

## EXPORT ALLOWED FUNCTIONS AND VARIABLES
### EXPORT HELPER METHODS
Export-ModuleMember -Function Get-SolutionFolder
Export-ModuleMember -Function Get-ProjectItem
Export-ModuleMember -Function Get-VisualStudioTemplate
Export-ModuleMember -Function Write-StepHeader
Export-ModuleMember -Function Write-StepInfo

### EXPORT MAIN TASK METHODS
Export-ModuleMember -Function Invoke-ViusalStudioSolution
Export-ModuleMember -Function Invoke-ModuleFileSetup
Export-ModuleMember -Function Invoke-SerializationProject
Export-ModuleMember -Function Invoke-CreateModule
Export-ModuleMember -Function Invoke-SolutionRootPath
Export-ModuleMember -Function Invoke-NewModule

