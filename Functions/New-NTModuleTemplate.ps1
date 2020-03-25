function New-NTModuleTemplate {
	<#
    .SYNOPSIS
    Generate module scaffolding and boilerplate.

    .DESCRIPTION
    Creates the following:

    - Public, Private, Tests & Classes directories for storing module functions.

    - A psm1 script that dot sources functions from Public & Private, but exports
      only those in Public.

    - A manifest file.

    - Two scripts in the root of the module that are dot sourced in the .psm1
      file. One defines color splatting hash tables, the other provides support
      for storing sensitive data in variables in a Config.psd1 file that is
      ignored by git.

    .PARAMETER Names
    The names of the modules you want to create.

    .PARAMETER Path
    The path to store these modules in. Defaults to the last path found in
    $env:PSModulePath.

    .PARAMETER Author
    Name of the modules author. This will be inserted into the Author and
    Copyright fields in the manifest file. Defaults to the current users' name.

    .PARAMETER CompanyName
    This will be inserted into the Company field of the manifest file. Defaults
    to nil.

    .PARAMETER Description
    Description of the module. This will be inserted into the description field
    of the module manifest and at the top of the main README.md.

    .PARAMETER RequiredModules
    List of modules that this module depends on. Will be inserted into the
    RequiredModules field of the manifest file.

    .PARAMETER UncommentConfig
    A switch that uncomments a line in the psm1 file that dot sources the
    configuration management script. This is stored in Config.ps1 and allows
    reading in of sensitive data stored in a Config.psd1 for setting variables
    available in the modules' scope.

    .EXAMPLE
    $Params = @{
	Name = Module1,Module2,Module3
	Path = "C:\MyModules"
	Author = "Me Myself & I"
	CompanyName = "My Awesome Company"
	Description = "This module will rock your world!"
	RequiredModules = 'All','My','Other','Modules'
    }
    New-ModuleTemplate @Params
    #>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string[]]$Names,
		[System.IO.DirectoryInfo]$Path = $(Get-Item -Path .\).FullName,
		[string]$Author = $env:USER,
		[string]$CompanyName = "",
		[string]$Description = "Module Description",
		[string[]]$RequiredModules = @(),
		[switch]$UncommentConfig
	)

	begin {
		if ((Test-Path -Path $PSScriptRoot\Templates) -eq $false) {
			Write-Warning "Make sure to download the Templates folder with the function and place it in the same directory as the function."
			break
		}
		$Templates = "$PSScriptRoot\Templates"
		$Module = "$Templates\Module.psm1"
		$Config = "$Templates\Config.ps1"
		$Colors = "$Templates\Colors.ps1"
		$GitIgnore = "$Templates\GitIgnore"
	}

	process {
		foreach ($Name in $Names) {
			$Directories = @(
				'Classes'
				'Public'
				'Private'
				'Public\Tests'
				'Private\Tests'
			)
			foreach ($Directory in $Directories) {
				New-Item -Name "$Path\$Name\$Directory" -ItemType Container
				Set-Content -Value "# $Name $Directory Functions" -Path "$Path\$Name\$Directory\README.md"
				Write-Verbose "Generated $Path\$Name\$Directory."
			}

			Set-Content -Value "# $Name Powershell Module" -Path "$Path\$Name\README.md"
			Add-Content -Value "`n*$Description*`n" -Path "$Path\$Name\README.md"

			Copy-Item $Config "$Path\$Name\Config.ps1"
			Write-Verbose "Copied $Config to $Path\$Name\Config.ps1."

			if ($UncommentConfig) {
				(Get-Content $Module) -Replace ('\#\.\s', '. ') |
		  Set-Content "$Path\$Name\$Name.psm1"
			}
			else {
				Copy-Item $Module "$Path\$Name\$Name.psm1"
			}
			Write-Verbose "Copied $Module to $Path\$Name\$Name.psm1."

			Copy-Item $Colors "$Path\$Name\Colors.ps1"
			Write-Verbose "Copied $Colors to $Path\$Name\Colors.ps1."

			$Params = @{
				Path              = "$Path\$Name\$Name.psd1"
				RootModule        = $Name
				Author            = $Author
				Copyright         = "(c) $(Get-Date -Uformat %Y) $Author. All rights reserved."
				CompanyName       = $CompanyName
				Description       = $Description
				RequiredModules   = $RequiredModules
				FunctionsToExport = '*'
				AliasesToExport   = '*'
				VariablesToExport = '*'
				CmdletsToExport   = '*'
			}
			New-ModuleManifest @Params
			Write-Verbose "Generated $Module manifest at $Path\$Name\$Name.psd1."

			Copy-Item $GitIgnore "$Path\$Name\.gitignore"
			Write-Verbose "Copied $GitIgnore to $Path\$Name\.gitignore."
		}
	}
}
