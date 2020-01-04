Set-StrictMode -Version 2.0

## PRIVATE METHODS - start ##

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
# Private Method
##############################
function Write-StepHeader {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        [Parameter(Mandatory = $true)]
        [string]$TaskType,
        [Parameter(Mandatory = $false)]
        [string]$TextColor = 'Green'
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
        if ($value.Length -gt $length) {
            # Reduce to length - 4 for elipsis
            $value = $value.Substring(0, $length - 4) + '...'
        }

        $value = " $value "
        if ($padright) {
            $value = $value.PadRight($length, '-')
        }
        else {
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
    try {
        $dte.Solution.SaveAs($dte.Solution.FullName)
        Write-Host "$($dte.Solution.FullName) Successfully saved."  
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
function Add-FolderToProjectItem {
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [object]$ProjectItem,
        [Parameter(Position = 1, Mandatory = $True)]
        [string]$FolderName
    )
    try {
        $folderItem = Get-ProjectItem -ProjectItem $ProjectItem -ItemName $FolderName

        if ($folderItem -eq $null) {
            $folderItem = $ProjectItem.ProjectItems.AddFolder($FolderName)
        }
        else {
            Write-Host "$FolderName already existed"
        }

        return $folderItem
    }
    catch {
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Creates a folder on the file system and then a parallel Solution folder.
#
#.DESCRIPTION
# Creates a folder on the file system and then a parallel Solution folder.
#
# .PARAMETER SourceFolderPath
# The fully qualified path(on the file system) to parent of the directory that is to be created
#
# REQUIRED
#
# .PARAMETER FolderName
# Name of the folder that will be created on the file system as well as have a solution folder added.
#
# REQUIRED
#
#.EXAMPLE
# 
# #To Run
# > Add-SolutionFolder -SourceFolderPath 'C:\Repo\Helix.Sample\src' -FolderName Foundation
#
#.NOTES
# Private Method
##############################
function Add-SolutionFolder {
    param(
        [parameter(Mandatory = $true)]
        [string]$SourceFolderPath,
        [parameter(Mandatory = $true)]
        [string]$FolderName
    )

    #CHECK DIRECTORY, CREATE IF NEEDED
    if (-NOT (Test-path -Path $SourceFolderPath)) {
        Write-Host "$SourceFolderPath directory does not exist, going to create it"
        New-Item -Path $SourceFolderPath -ItemType Directory
    }

    Write-Host 'Create $FolderName folder in solution and on file system'
    New-Item -Path $SourceFolderPath -Name $FolderName -ItemType Directory
    return $dte.Solution.AddSolutionFolder($FolderName)
}

##############################
#.SYNOPSIS
# Performs a NuGet Package Install (ie Install-Package) to the given project ($ProjectName).
# If no $PackageVersion is given the latest version is installed.
#
#.DESCRIPTION
# Performs a NuGet Package Install (ie Install-Package) to the given project ($ProjectName).
# If no $PackageVersion is given the latest version is installed.
#
#.PARAMETER ProjectName
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
#.EXAMPLE 1
# > Add-PackageToModule -ProjectName 'Coffeehouse.Feature.CouponCode' -PackageName 'Sitecore.Kernel.NoReference'
#
#.EXAMPLE 2
# > Add-PackageToModule -ProjectName 'Coffeehouse.Feature.CouponCode' -PackageName 'Microsoft.Extensions.DependencyInjection.Abstraction' -PackageVersion '1.0.0'
#
#.NOTES
# Private Method
##############################
function Add-PackageToModule {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$PackageName,
        [Parameter( Mandatory = $false)]
        [string]$PackageVersion
    )
    try {
        if ($PackageVersion) {
            Install-Package $PackageName -ProjectName $ProjectName $PackageVersion
        }
        else {
            Install-Package $PackageName -ProjectName $ProjectName
        }
    }
    catch {
        Write-Error $_ -ErrorAction Continue
    }
}

##############################
#.SYNOPSIS
# For the given project ($ProjectName) performs some basic setup of the project for use.
# Elements that are configured for the project are:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.2
#   * NuGet Install of - Sitecore.Kernel 
#   * NuGet Install of - Sitecore.Mvc 
#   * Set all Reference DLLs to be Copy Local = False
#   
#.DESCRIPTION
# For the given project (ProjectName) performs some basic setup of the project for use.
# Elements that are configured for the project are:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.2
#   * NuGet Install of - Sitecore.Kernel 
#   * NuGet Install of - Sitecore.Mvc 
#   * Set all Reference DLLs to be Copy Local = False
#   
#.PARAMETER ProjectName
# Name of the project to be updated
#
# REQUIRED
# 
#.PARAMETER SitecoreVersion
# Optional parameter, that identifies which version of Sitecore NuGet Packages will be installed.
# If no value is provided the latest version will be installed.
#
# Parameter validation will force proper formatt of #.#.#### for example 9.0.171219
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$|\s*
#
#
# DEAULT VALUE: 9.3.0
#
# OPTIONAL
#
#.PARAMETER DotNETTargetFramework
# Enter the version of the .NET Framwork that the project should build as.
#
# For reference: 262662 - representing 4.6.2
# For reference: 262407 - representing 4.7.1
# DEFAULT VALUE: 262663 - representing 4.7.2
#
# OPTIONAL
#
#.EXAMPLE 1
# > Set-ModuleFiles -ProjectName 'Coffeehouse.Feature.CouponCode'
# 
#.EXAMPLE 2
# > Set-ModuleFiles -ProjectName 'Coffeehouse.Feature.CouponCode' -SitecoreVersion '8.2.161115'
#
#.EXAMPLE 3
# > Set-ModuleFiles -ProjectName 'Coffeehouse.Feature.CouponCode' -SitecoreVersion '8.2.161115' -DotNETTargetFramework '25023'
#
#.NOTES
# Private Method
##############################
function Set-ModuleFiles {
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [string]$ProjectName,
        [Parameter(Position = 1, Mandatory = $false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$|\s*")]
        [string] $SitecoreVersion = "9.3.0",
        [Parameter(Position = 2, Mandatory = $false)]
        [string] $DotNETTargetFramework = '262663'
    )
    try {
        Write-Host "Set Module Files: Save Solution to ensure clean start"
        Save-VisualStudioSolution

        #Get Module Project
        Write-Host "Set Module Files: Get $ProjectName from Solution"
        $moduleProj = Get-Project $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Set Module Files: Project named $ProjectName not found" -ForegroundColor Red
            Write-Host "Set Module Files: Canceled - no file setup can happen" -ForegroundColor Red
            return
        }

        #Get Web.config and set to BUILD ACTION = NONE
        $webConfig = $moduleProj.ProjectItems | Where-Object { $_.Name -eq 'Web.config' }
        if ($webConfig -ne $null) {
            Write-Host "Set Module Files: Setting web.config build action to none"
            ($webConfig.Properties | Where-Object { $_.Name -eq 'BuildAction' }).Value = 0
            Save-VisualStudioSolution
        }

        $moduleProj = Get-Project -Name $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Set Module Files: Project named $ProjectName not found" -ForegroundColor Red
            Write-Host "Set Module Files: Canceled - no file setup can happen" -ForegroundColor Red
            return
        }
        # #Set Target Framework
        Write-Host "Set Module Files: Set Target Framework to $DotNETTargetFramework"
        $moduleProj.Properties["TargetFramework"].Value = $DotNETTargetFramework      
        Save-VisualStudioSolution

        ##Need to reload object for additional work.
        $moduleProj = Get-Project -Name $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Set Module Files: Project named $ProjectName not found" -ForegroundColor Red
            Write-Host "Set Module Files: Canceled - no file setup can happen" -ForegroundColor Red
            return
        }

        #Install Sitecore.Kernel
        Write-Host "Set Module Files: Add Sitecore.Kernel version $SitecoreVersion"
        Add-PackageToModule -ProjectName $ProjectName -PackageName "Sitecore.Kernel" -PackageVersion $SitecoreVersion
        $moduleProj.Save()

        #Install Sitecore.MVC.NoReference
        Write-Host "Set Module Files: Add Sitecore.MVC version $SitecoreVersion"
        Add-PackageToModule -ProjectName $ProjectName -PackageName "Sitecore.Mvc" -PackageVersion $SitecoreVersion
        $moduleProj.Save()
        $appStartPath = $moduleProj.ProjectItems["App_Start"].Properties["FullPath"].Value
        $moduleProj.ProjectItems["App_Start"].Remove()
        Remove-Item $appStartPath -Recurse
        $moduleProj.Save()

        #Set All Assemblies as CopyLocal = False
        Write-Host "Set Module Files: Setting all references to Copy Local = False"
        $moduleProj.Object.References | ForEach-Object { try { $_.CopyLocal = $false }catch { } }        
        $moduleProj.Save()

        #SAVE SOLUTION - not sure if it is needed but just feels right to do a save after this work.
        Write-Host "Set Module Files: Save Solution"
        Save-VisualStudioSolution
    }
    catch {
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
#.PARAMETER ProjectName
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
# > Add-ModuleConfigFile -ProjectName 'Coffeehouse.Feature.CouponCode' -Layer 'Feature' -TemplatePath "C:\Programs\VS\webconfig.vstemplate"
#
#.NOTES
# Private Method
##############################
function Add-ModuleConfigFile {
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [string]$ProjectName,
        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateSet("Feature", "Foundation", "Project")]
        [string]$Layer,		
        [Parameter(Position = 2, Mandatory = $True)]
        [string]$TemplatePath,
        [Parameter(Position = 3, Mandatory = $false)]
        [switch]$IncludeUnicorn
    )
    try {

        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Add Module Config Files: Project named $ProjectName not found" -ForegroundColor Red
            Write-Host "Add Module Config Files: No file setup can happen"  -ForegroundColor Red
            return
        }

        $namespace = $moduleProj.Properties["DefaultNamespace"].Value

        # App_Config
        $appConfigFolderObj = Get-ProjectItem -ProjectItem $moduleProj -ItemName "App_Config"
        if (-Not $appConfigFolderObj) {
            Write-Host "Add Module Config Files: Create App_Config"
            $appConfigFolderObj = $moduleProj.ProjectItems.AddFolder("App_Config")
        }

        $includeConfigFolderObj = Get-ProjectItem -ProjectItem $moduleProj -ItemName "Include"
        if (-Not $includeConfigFolderObj) {
            Write-Host "Add Module Config Files: Create App_Config\Include"
            $includeConfigFolderObj = $appConfigFolderObj.ProjectItems.AddFolder("Include")
        }

        $layerFolderObj = Get-ProjectItem -ProjectItem $moduleProj -ItemName $Layer
        if (-Not $layerFolderObj) {
            Write-Host "Add Module Config Files: Create App_Config\Include\$Layer"
            $layerFolderObj = $includeConfigFolderObj.ProjectItems.AddFolder($Layer)
        }

        $moduleProj.Save()
        Save-VisualStudioSolution

        $layerFolderObj = Get-ProjectItem -ProjectItem $moduleProj -ItemName $Layer
        $layerFolderPath = $layerFolderObj.Properties["LocalPath"].Value
        Write-Host "Add Module Config Files: Create DI Config"
        #Create Default Configurations
        $configTemplate = @"
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/">
  <sitecore>
    <services>
      <configurator type="{0}.DI.RegisterContainer, {0}" />
    </services>
      <settings>        
      </settings>
  </sitecore>
</configuration>
"@

        Write-Host " Add Module Config Files: DI Config Set content"
        Set-Content -Path "$layerFolderPath\$namespace.config" -Value $($configTemplate -f $namespace)        

        Write-Host "Create DI Config: Add to Project"
        $configPath = $layerFolderPath + "$namespace.config"
        Write-Host "Create DI Config: $configPath"
        $layerFolderObj.ProjectItems.AddFromFile($configPath)
    
        if ($IncludeUnicorn) {
            Write-Host "Add Unicorn config"
            $configTemplate = @"
            <!--See Unicorn.config for commentary on how configurations operate, or https://github.com/kamsar/Unicorn/blob/master/README.md-->
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/">
  <sitecore>
    <unicorn>
      <configurations>
        <configuration name="{1}" description="{0} {1}" dependencies="Foundation.*" extends="Helix.Base">
          <predicate>
            <include name="Templates" database="master" path="/sitecore/templates/{0}/{1}"/>
            <include name="Renderings" database="master" path="/sitecore/layout/Renderings/{0}/{1}"/>            
          </predicate>
        </configuration>
      </configurations>
    </unicorn>
  </sitecore>
</configuration>
"@

            $configFileName = "{0}.Serialization.config" -f $namespace
            Write-Host "Unicorn Config: Set content"
            Set-Content -Path "$layerFolderPath\$configFileName" -Value $($configTemplate -f $Layer, $ModuleName)
          
            Write-Host "Unicorn Config: Add to Project"
            $configPath = $layerFolderPath + $configFileName
            
            Write-Host "Unicorn Config: $configPath"
            $layerFolderObj.ProjectItems.AddFromFile($configPath)

        }     

        Write-Host "Add Module Config Files: $projModuleName Saving module (project)"
        $moduleProj.Save()
        Save-VisualStudioSolution
        Write-Host "Add Module Config Files: $projModuleName Module specific config update complete"
    }
    catch {
        Write-Error $_ -ErrorAction Continue
        throw
    }
}


##############################
#.SYNOPSIS
# Adds default folders to a Helix based project for 
# * DI
# * Views
# * Views\<ModuleName>
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
# * Views\<ModuleName>
# * Repositories
# * Constants
# * Controllers
# * Models
#
# Folders are created via a call to Add-FolderToProjectItem, which creates the folder both in the solution and on the file system
#
#.PARAMETER ProjectName
# Name of the project being updated
#
#.EXAMPLE
# > Add-ModuleDefaultFolders -ProjectName 'Coffeehouse.Feature.CouponCode'
#
#.NOTES
#Private Method
##############################
function Add-ModuleDefaultFolders {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )
    try {
        Write-Host "Add Module Default Folders: $ProjectName Begin"

        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Add Module Default Folders: Project ProjectName not found" 
            Write-Host "Add Module Default Folders: $ProjectName no setup can happen" 
            return
        }
        #Create Folders
        ## DI Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'DI'

        ## Views Folder
        $viewFolder = Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Views'
        Add-FolderToProjectItem -ProjectItem $viewFolder -FolderName $($ProjectName.Split(".") | Select-Object -Last 1)
        
        ## Repositories Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Repositories'
        ## Constants Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Constants'
        ## Models Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Models'
        ## Controllers Folder
        Add-FolderToProjectItem -ProjectItem $moduleProj -FolderName 'Controllers'
        
        Write-Host "Add Module Default Folders: $ProjectName Saving module (project)"
        $moduleProj.Save()
        Write-Host "Add Module Default Folders: $ProjectName Save Solution"
        Save-VisualStudioSolution
        Write-Host "Add Module Default Folders: $ProjectName Completed"
    }
    catch {
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
#.PARAMETER ProjectName
# Name of project (module) that the register container should be created for
# Example: Coffeehouse.Feature.CouponCode
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
function Add-RegisterContainerClass {
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [string]$ProjectName,
        [Parameter(Position = 1, Mandatory = $True)]
        [string]$ClassTemplatePath
    )
    try {
        Write-Host "Add Register Container Class: $ProjectName Begin"
        Save-VisualStudioSolution
        #Load Project
        $moduleProj = Get-Project -Name $ProjectName
        if ($moduleProj -eq $null) {
            Write-Host "Add Register Container Class: Project $ProjectName not found" 
            Write-Host "Add Register Container Class: No setup can happen" 
            return
        }
       
        $DIFolder = Get-ProjectItem -ProjectItem $moduleProj -ItemName 'DI'
        if ($DIFolder -ne $null) {
            Write-Host "Add Register Container Class: $ProjectName Creating RegisterContainer.cs in solution"
            $ModuleFileSystemPath = Split-Path $moduleProj.FullName
            $DIFolder.ProjectItems.AddFromTemplate($ClassTemplatePath, "RegisterContainer.cs")
            $moduleProj.Save()

            Save-VisualStudioSolution

            Write-Host "Add Register Container Class: $ProjectName Begin content update"
            $RegisterTemplate = @"
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
            $rt = $RegisterTemplate.Replace("MODULENAME", $($moduleProj.Properties["DefaultNamespace"].Value))
            Write-Host "Add Register Container Class: Updating contents of RegisterContainer.cs"
            Set-Content -Path $($ModuleFileSystemPath + '\DI\RegisterContainer.cs') -Value $rt
            Write-Host "Add Register Container Class: Content update for $($ModuleFileSystemPath+'\DI\RegisterContainer.cs')"
        }
    }
    catch {
        Write-Error $_ -ErrorAction Continue
        throw
    }
}


##############################
#.SYNOPSIS
# Performs a number of differnt steps in setting up and configuring the Module Web project.
#
# STEP 1: Configures the following for the project:
#   * Web.config build action is set to NONE
#   * Set Target .NET Framework to given value or default of 4.7.2
#   * NuGet Install of - Sitecore.Kernel version 9.3.0
#   * NuGet Install of - Sitecore.Mvc version 9.3.0
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
#   * Set Target .NET Framework to given value or default of 4.7.2
#   * NuGet Install of - Sitecore.Kernel version 9.3.0
#   * NuGet Install of - Sitecore.Mvc version 9.3.0
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
# Name of the Module, this should NOT include the namespace
# Example, correct: PageContent
# Example, not correct: Coffeehouse.Feature.PageContent
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
# If no value is provided the latest version will be installed. (9.3.0)
#
# Parameter validation will force proper formatt of #.#.#### for example 9.0.171219
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$|\s*
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
#.PARAMETER UseUnicorn
# Switch (flag) parameter.
# Include flag to setup Unicorn serialization config files.
#
# OPTIONAL
#
#.EXAMPLE 1
# > Invoke-ModuleFileSetup -ModuleName "ShoppingHistory" -Layer "Feature" -UseUnicorn
#
#.EXAMPLE 2
# > Invoke-ModuleFileSetup -ModuleName "ShoppingHistory" -Layer "Feature" -SitecoreVersion 9.2.0
#
#.NOTES
# Priavte Method
##############################
function Invoke-ModuleFileSetup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$ModuleName,
        [parameter(Mandatory = $true)]
        [ValidateSet("Feature", "Foundation", "Project")]
        [string]$Layer,        
        [parameter(Mandatory = $false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$|\s*")]      
        [string]$SitecoreVersion = "9.3.0",
        [parameter(Mandatory = $false)]        
        [string]$TemplateName = "Class.vstemplate",
        [parameter(Mandatory = $false)]        
        [string]$TemplateFilter = '*Web\CSharp\*', 
        [parameter(Mandatory = $false)]
        [switch]$UseUnicorn
    )

    PROCESS {
        Write-StepHeader "$ModuleName - File Setup"  -TaskType "Module"
        $projModuleName = "$($dte.Solution.Properties["Name"].Value).$Layer.$ModuleName"
        if ($pscmdlet.ShouldProcess("$ModuleName", "Begin file setup of new Module")) {
            
            ##STEP 1: Install NuGet Packages, Set References to not copy
            Write-Host "Setup: $ModuleName 1. Set Module Files"
            Set-ModuleFiles -ProjectName $projModuleName -SitecoreVersion $SitecoreVersion

            ##STEP 2: Added Module Config File
            $webConfigTemplate = Get-VisualStudioTemplate -TemplateName 'WebConfig.vstemplate' -FilterValue '*CSharp\Web*'
            Write-Host "Setup: $ModuleName 2. Create Module Config File"
            Add-ModuleConfigFile -ProjectName $projModuleName -Layer $Layer -TemplatePath $webConfigTemplate -IncludeUnicorn:$UseUnicorn

            ##STEP 3: Created Default folders: DI, Views, Repositories, Constants, Controllers, Models
            Write-Host "Setup: $ModuleName 3. Begin Module Default File Creation (DI, Views, Repositories, Constants, Controllers, Models"
            Add-ModuleDefaultFolders -ProjectName $projModuleName

            ##STEP 4: 
            Write-Host "Setup: $ModuleName 4. Create and update RegisterContainer.cs"
            $classTemplatePath = Get-VisualStudioTemplate -TemplateName $TemplateName -FilterValue $TemplateFilter
            Add-RegisterContainerClass -ProjectName $projModuleName -ClassTemplatePath $classTemplatePath
        }
    }
}

## PRIVATE METHODS - end ##

## PUBLIC METHODS - start ##

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
# Default is to a 2019 Visual Studio Installation
# DEFAULT VALUE: 'C:\Program Files (x86)\Microsoft Visual Studio\2019'
#
# OPTIONAL
#
# ex: 'C:\Program Files (x86)\Microsoft Visual Studio\2019'
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
function Get-VisualStudioTemplate {
    param( 
        [parameter(Position = 0, Mandatory = $true)]
        [string]$TemplateName,
        [parameter(Mandatory = $false)]
        [string]$DefaultVisualStudioInstall = 'C:\Program Files (x86)\Microsoft Visual Studio\2019',        
        [parameter(Mandatory = $false)]
        [string]$FilterValue
    )
    try {
        if ($FilterValue) {
            return (Get-ChildItem -Path $DefaultVisualStudioInstall -Filter $TemplateName -Recurse -ErrorAction SilentlyContinue -Force | Where-Object { $_.FullName -like $FilterValue } | Select-Object -First 1).FullName
        }
        else {
            return (Get-ChildItem -Path $DefaultVisualStudioInstall -Filter $TemplateName -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1).FullName    
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
function Get-SolutionFolder {
    param(  [parameter(Mandatory = $true)]
        [string]$ItemName)
    try {

        return $dte.Solution.Projects | Where-Object { $_.Name -eq $ItemName } | Select-Object -First 1

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
# Public Method
##############################
function Get-ProjectItem {
    param(  
        [parameter(Mandatory = $true)]
        [object]$ProjectItem,
        [parameter(Mandatory = $true)]
        [string]$ItemName
    )
    try {
        if ($ProjectItem.Name -eq $ItemName) {
            Write-Host "$ItemName Found project item"
            return $ProjectItem
        }

        foreach ($pi in $ProjectItem.ProjectItems) {
            $temp = Get-ProjectItem $pi $ItemName
            if ($temp -ne $null) {                   
                return $temp
            }
        }        
        return $null
    }
    catch {
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Creates a new Visual Studio Solution at the given Directory Path with base folders
#
# File System will look like the following
# - Directory Path
# -- Solution Name
# -- SolutionName.sln
# -- lib
# -- __Documents
# -- __Scripts
# -- src
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
# -- __Documents
# -- __Scripts
# -- src
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
#.EXAMPLE
# > New-VisualStudioSoltion -SolutionName 'Helix.Demo.Solution' -DirectoryPath 'C:\Code\MySamples'
#
#.NOTES
# Public Method
##############################
function Invoke-VisualStudioSolution {
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$SolutionName,
        [parameter(Position = 1, Mandatory = $true)]
        [string]$DirectoryPath
    )
    try {
        #CHECK DIRECTORY, CREATE IF NEEDED
        if (-NOT (Test-path -Path $DirectoryPath)) {
            Write-Host "$DirectoryPath does not exist, going to create it"
            New-Item -Path $DirectoryPath -ItemType Directory
        }
        
        $slnPath = ($DirectoryPath + '\' + $SolutionName)

        #CHECK DIRECOTORY for SOLTUION FOLDER
        if (-NOT (Test-Path -Path $slnPath)) {
            New-Item -Path $slnPath -ItemType Directory
        }

        $slnNameExt = $SolutionName + '.sln'

        #CREATE SOLUTION
        Write-Host  "Creating and saving new solution: $SolutionName"
        $dte.Solution.Create($slnPath, $slnNameExt)
        $dte.Solution.SaveAs($slnPath + '\' + $slnNameExt)
        
        #CREATE FILE SYSTEM and MATCHING SOLUTION FOLDERS
        #- create SRC folder    
        $slnSrcPath = (New-Item -Path $slnPath -Name 'src' -ItemType Directory).FullName
        
        #- create Feature Folder
        Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "Feature"
        
        #- create Foundation Folder
        Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "Foundation"

        #- create Project Folder
        Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "Project"

        # #- create __Documents Folder
        Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "__Documents"

        # #- create __Scripts Folder
        Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "__Scripts"
     
        #- create  lib Folder
        Write-Host 'Create lib folder on file system'
        New-Item -Path $slnPath -Name 'lib' -ItemType Directory

        #SAVE AS REQUIRED TO ENSURE CHANGES TAKE AFFECT
        Save-VisualStudioSolution
        
        $slnFullPath = $slnPath + '\' + $slnNameExt
        return $slnFullPath
    }
    catch {        
        Write-Error $_ -ErrorAction Continue
        throw
    }
}

##############################
#.SYNOPSIS
# Creates a new Empty Web Application Project under the identified Layer.
# Name of project will take the form of: <Solution Name>.<Layer>.<Module Name>
# Returns the name of the project
#
# IMPORTANT: before this can be ran you must 'wake-up' the $dte object by running the following:
#       > $dte.Solution.FullName
#
# If you do NOT 'wake-up' the console Visual Studio will freeze when creating the Empty Web Application Project
#
#.DESCRIPTION
# Creates a new Empty Web Application Project under the identified Layer.
# Name of project will take the form of: <Solution Name>.<Layer>.<Module Name>
# Returns the name of the project
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
#.PARAMETER ModuleProjectTemplate
# Path and File name to the project template that is to be created.
# This value is normally retreived via a call to Get-VisualStudioTemplate
#
# DEFAULT VALUE: 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\ProjectTemplates\CSharp\Web\1033\WebApplicationProject40\EmptyWebApplicationProject40.vstemplate'
#
# OPTIONAL
#
#.PARAMETER SourceCodeFolderName
# Value that project code should be placed in.
#
# DEFAULT VALUE: website 
#
# OPTIONAL
#
#.EXAMPLE 1
# > Invoke-CreateModuleProject -ModuleName "Search" -Layer "Foundation"
#
#.EXAMPLE 2
# > Invoke-CreateModuleProject -ModuleName "Search" -Layer "Foundation" -ModuleProjectTemplate 'C:\Program\VS\2019\WebApp.vstemplate'
#
#.NOTES
# Public Method
##############################
function Invoke-CreateModuleProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory = $true)]
        [string]$ModuleName,
        [parameter( Mandatory = $true)]
        [ValidateSet("Feature", "Foundation", "Project")]
        [string]$Layer,
        [Parameter( Mandatory = $false)]
        [string]$ModuleProjectTemplate = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\ProjectTemplates\CSharp\Web\1033\WebApplicationProject40\EmptyWebApplicationProject40.vstemplate',
        [Parameter(Mandatory = $false)]
        [string]$SourceCodeFolderName = 'website'
    )

    PROCESS { 
        Write-StepHeader "$Layer - $ModuleName - Create New Module" -TaskType "Module"
        if ($pscmdlet.ShouldProcess("$ModuleName", "Begin Project Creation")) {
            $templatePath = Get-VisualStudioTemplate -TemplateName 'EmptyWebApplicationProject40.vstemplate' -FilterValue "*\CSharp\Web\*"        
            Write-Host "$ModuleName Project Template: $templatePath"
            $slnPath = Invoke-SolutionRootPath
            
            try {
                Write-Host "$ModuleName Save Solution to ensure it is clean before project creation"
                Save-VisualStudioSolution

                #Check that the module does not already exist in solution
                $slnFolderObj = Get-SolutionFolder $ModuleName
                if ($slnFolderObj -ne $null) {
                    Write-Host "$ModuleName Folder with module name already exists in solution."
                    Write-Host "$ModuleName $ModuleName will not be created."
                    return
                }

                $SourceCodeRootPath = Invoke-SolutionRootPath

                #Check that the project does not exist on the file system
                Write-Host "$ModuleName - Path Creation Path format: {0}\{1}\{2}\{3}"
                Write-Host "$ModuleName - Path Creation Part 0: $SourceCodeRootPath"
                Write-Host "$ModuleName - Path Creation Part 1: $Layer"
                Write-Host "$ModuleName - Path Creation Part 2: $ModuleName"   
                Write-Host "$ModuleName - Path Creation Part 3: $SourceCodeFolderName"   
                $modulePath = "{0}\{1}\{2}\{3}" -f $SourceCodeRootPath, $Layer, $ModuleName, $SourceCodeFolderName
                Write-Host "$ModuleName - Path Creation Final Path: $modulePath"

                if (Test-Path $modulePath) {
                    Write-Host "$ModuleName - $modulePath exists on the file system"
                    Write-Host "$ModuleName - $ModuleName will not be created."
                    return
                }

                $layerFolder = Get-SolutionFolder $Layer 	
                if ($layerFolder -eq $null) {
                    Write-Host "$ModuleName - $Layer solution folder does not exist., so creating"
                    $layerFolder = Add-SolutionFolder -SourceFolderPath $slnSrcPath -FolderName "$Layer"
                }
        
                #Add module folder to solution
                Write-Host "$ModuleName - Solution Folder added"
                $sf = $layerFolder.Object.AddSolutionFolder($ModuleName)           
                Write-Host "$ModuleName - Save Solution Saving Solution after folder add"        
                Save-VisualStudioSolution

                Write-Host "$ModuleName - Module Folder $($sf.ProjectName)"        
                Write-Host "$ModuleName - Project Creation Template: $ModuleProjectTemplate"
                Write-Host "$ModuleName - Project Creation Path: $modulePath"
                Write-Host "$ModuleName - Project Creation Name: $ModuleName"

                $layerFolder = Get-SolutionFolder $Layer
                $sp = Get-ProjectItem $layerFolder $ModuleName
                if (-NOT $sp) {
                    Write-Host "$ModuleName  Solution Folder for Module Not Found"
                    return
                }
                $projName = "$($dte.Solution.Properties["Name"].Value).$Layer.$ModuleName"
                $sp.SubProject.Object.AddFromTemplate($ModuleProjectTemplate, $modulePath, $projName)

                Write-Host "$ModuleName - Save Solution Saving Solution after project add"
                Save-VisualStudioSolution
                Write-Host "Module created: $projName"

                return $projName
            }
            catch {
                Write-Error $_ -ErrorAction Continue
                throw
            }
       
        }
    }
}   

##############################
#.SYNOPSIS
# Creates a serialization project for the named module
#
#.DESCRIPTION
# Creates a serialization project for the named module
#
#.PARAMETER ProjectName
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
# > Invoke-SerializationProject -ProjectName "Coffeehouse.Foundation.Search" -Layer "Foundation" -UseTDS
#
# > Invoke-SerializationProject "Coffeehouse.Foundation.Search" "Foundation" -UseTDS
#
#.NOTES
# UseUnicorn switch currently does nothing, this is for future use.
##############################
function Invoke-SerializationProject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$ProjectName,
        [parameter(Position = 1, Mandatory = $true)]
        [ValidateSet("Feature", "Foundation", "Project")]
        [string]$Layer,
        [parameter(Mandatory = $false)]
        [switch]$UseTDS,
        [parameter(Mandatory = $false)]
        [switch]$UseUnicorn
    )
    PROCESS { 
        Write-Host "Setup Serialization: for $ProjectName"

        if ($pscmdlet.ShouldProcess("$ProjectName", "Begin Serialziation Project setup")) {
            $ModuleName = $ProjectName.Split(".") | Select-Object -Last 1
            $SourceCodeRootPath = Invoke-SolutionRootPath
            if ($UseTDS) {
                Write-Host "Setup Serialization: TDS Setup"

                $tdsProjectName = "$ProjectName.TDS.Master"
                $SourceCodeFolderName = 'tds'

                Write-Host "Setup Serializaton: $tdsProjectName Path format: {0}\{1}\{2}\{3}\{4}"
                Write-Host "Setup Serializaton: $tdsProjectName Path Part 0: $SourceCodeRootPath"
                Write-Host "Setup Serializaton: $tdsProjectName Path Part 1: $Layer"
                Write-Host "Setup Serializaton: $tdsProjectName Path Part 2: $ModuleName"   
                Write-Host "Setup Serializaton: $tdsProjectName Path Part 3: $SourceCodeFolderName"
                Write-Host "Setup Serializaton: $tdsProjectName Path Part 4: $tdsProjectName"   
                $modulePath = "{0}\{1}\{2}\{3}\{4}" -f $SourceCodeRootPath, $Layer, $ModuleName, $SourceCodeFolderName, $tdsProjectName

                Write-Host "Setup Serializaton: Final Path: $modulePath"   
                if (Test-Path $modulePath) {
                    Write-Host "Setup Serializaton: $modulePath exists on the file system"
                    Write-Host "Setup Serializaton: $tdsProjectName will not be created."
                    return
                }

                Write-Host "Setup Serializaton: Retrieve TDS Project Template - $ProjectTemplateName"
                $projecttemplate = Get-VisualStudioTemplate -TemplateName $ProjectTemplateName
                Write-Host "Setup Serializaton: Template Location: $projecttemplate"
                $sp.SubProject.Object.AddFromTemplate($projecttemplate, $modulePath, $tdsProjectName)
                Save-VisualStudioSolution
            }
            else {
                Write-Host "Setup Serialization: Unicorn Setup"            
                $modulePath = "{0}\{1}\{2}\{3}" -f $SourceCodeRootPath, $Layer, $ModuleName, "serialization"
                $fld = New-Item -Path $modulePath -ItemType Directory
                Write-Host "Setup Serialization: Unicorn setup created at $modulePath" 
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
function Invoke-SolutionRootPath {
    param(
        [parameter(Position = 0, Mandatory = $false)]
        [string]$SourceFolderName = 'src'
       
    )
    $basePath = Split-Path $dte.Solution.FullName
    return $basePath + '\' + $SourceFolderName
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
# Name of the Module, this should NOT include the namespace
# Example, correct: PageContent
# Example, not correct: Coffeehouse.Feature.PageContent
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
# Regex is: ^[7-9]{1}\.\d{1}\.\d{6}$|\s*
#
# DEFAULT: 9.3.0
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
#.PARAMETER CreateEmptyProject
# Switch (flag) parameter, only include if you wish to have an empty project created in the identified layer
#
# OPTIONAL
#
#.EXAMPLE 1
# > Invoke-NewModule -ModuleName "Ad" -Layer "Feature"
#
#.EXAMPLE 2
# > Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -UseTDS
#
#.EXAMPLE 3
# > Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -UseUnicorn
#
#.EXAMPLE 4
# > Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -SitecoreVersion "8.2.171121"
#
#.EXAMPLE 5
# > Invoke-NewModule -ModuleName "Ad" -Layer "Feature" -SitecoreVersion "8.2.171121" -UseUnicorn
#
#.NOTES
# Public Method
##############################
function Invoke-NewModule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter( Mandatory = $true)]
        [string]$ModuleName,        
        [parameter(Mandatory = $true)]
        [ValidateSet("Feature", "Foundation", "Project")]
        [string]$Layer,
        [parameter( Mandatory = $false)]
        [ValidatePattern("^[7-9]{1}\.\d{1}\.\d{6}$|\s*")]
        [string]$SitecoreVersion = "9.3.0",
        [parameter(Mandatory = $false)]
        [switch]$UseTDS,
        [parameter(Mandatory = $false)]
        [switch]$UseUnicorn,
        [parameter(Mandatory = $false)]
        [switch]$CreateEmptyProject
    )

    PROCESS {        
        if ($pscmdlet.ShouldProcess("$ModuleName", "Begin Module Creation and Population")) {
            Save-VisualStudioSolution

            Write-Host "Module Create Step 1: Create Module Project"
            $projName = Invoke-CreateModuleProject -ModuleName $ModuleName -Layer $Layer
            
            Save-VisualStudioSolution
            
            if (-Not $CreateEmptyProject) {
                Write-Host "Module Create Step 2: Setup Files"
                Invoke-ModuleFileSetup -ModuleName $ModuleName -Layer $Layer -SitecoreVersion $SitecoreVersion -UseUnicorn:$UseUnicorn
                Save-VisualStudioSolution
                if ($UseTDS -or $UseUnicorn) {
                    Write-Host "Module Create Step 3: Setup Serialization"
                    Invoke-SerializationProject -ProjectName "$projName" -Layer $Layer -UseTDS:$UseTDS -UseUnicorn:$UseUnicorn
                    Save-VisualStudioSolution
                }
                else {
                    Write-Host "Module Create Step 3: Setup Serialization - None Requested"
                }
            }
            Write-Host "** $projName Ready for Sitecore **" -ForegroundColor Yellow
        }
    }
}

## EXPORT ALLOWED FUNCTIONS AND VARIABLES
### EXPORT HELPER METHODS
Export-ModuleMember -Function Get-SolutionFolder
Export-ModuleMember -Function Get-ProjectItem
Export-ModuleMember -Function Get-VisualStudioTemplate

### EXPORT MAIN TASK METHODS
Export-ModuleMember -Function Invoke-VisualStudioSolution
Export-ModuleMember -Function Invoke-SerializationProject
Export-ModuleMember -Function Invoke-CreateModuleProject
Export-ModuleMember -Function Invoke-SolutionRootPath
Export-ModuleMember -Function Invoke-NewModule