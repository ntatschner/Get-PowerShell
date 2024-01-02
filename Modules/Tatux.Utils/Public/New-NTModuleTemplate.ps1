<#
    .SYNOPSIS
    Generate module scaffolding and boilerplate.

    .DESCRIPTION
    Creates the following:

    - Public, Private & Classes directories for storing module functions.

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
    New-NTModuleTemplate @Params
    #>
function New-NTModuleTemplate {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string[]]$Names,
		[System.IO.DirectoryInfo]$Path = $PWD.Path,
		[string]$Author = $env:USER,
		[string]$CompanyName = "",
		[string]$Description = "Module Description",
		[string[]]$RequiredModules = @(),
		[switch]$UncommentConfig
	)

	begin {
		$Templates = "$PSScriptRoot\..\Templates"
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
			$ParentPath = Join-Path -Path $Path -ChildPath $Name
			try {
				if (-not (Test-Path -Path $ParentPath)) {
					Write-Verbose "Creating Module path: $ParentPath."
					New-Item -Path $ParentPath -Type Directory -ErrorAction Stop
				}
			}
			catch {
				Write-Verbose "Failed to create Module path: $ParentPath."
				$_
				break
			}
			try {
				foreach ($Directory in $Directories) {
					$FullPath = Join-Path -Path $ParentPath -ChildPath $Directory
					if (-not (Test-Path -Path $FullPath)) {
						Write-Verbose "Creating path: $FullPath."
						New-Item -Path $FullPath -Type Directory -ErrorAction Stop
						Write-Verbose "Created path: $FullPath."
					}
					$ReadmePath = Join-Path -Path $FullPath -ChildPath "README.md"
					Set-Content -Value "# $Name $Directory" -Path $ReadmePath -ErrorAction Stop
				}
			}
			catch {
				Write-Verbose "Failed to create path: $FullPath."
				$_
				break
			}
	
			$ReadmePath = Join-Path -Path $Path -ChildPath "$Name\README.md"
			Set-Content -Value "# $Name Powershell Module" -Path $ReadmePath
			Add-Content -Value "`n*$Description*`n" -Path $ReadmePath
	
			$ConfigPath = Join-Path -Path $Path -ChildPath "$Name\Config.ps1"
			if (Test-Path -Path $Config) {
				Copy-Item $Config $ConfigPath
				Write-Verbose "Copied $Config to $ConfigPath."
			}
	
			if ($UncommentConfig) {
				$ModuleContent = Get-Content $Module
				$ModulePath = Join-Path -Path $Path -ChildPath "$Name\$Name.psm1"
				$ModuleContent -Replace ('\#\.\s', '. ') | Set-Content $ModulePath
			}
			else {
				$ModulePath = Join-Path -Path $Path -ChildPath "$Name\$Name.psm1"
				if (Test-Path -Path $Module) {
					Copy-Item $Module $ModulePath
				}
			}
			Write-Verbose "Copied $Module to $ModulePath."
	
			$ColorsPath = Join-Path -Path $Path -ChildPath "$Name\Colors.ps1"
			if (Test-Path -Path $Colors) {
				Copy-Item $Colors $ColorsPath
				Write-Verbose "Copied $Colors to $ColorsPath."
			}
	
			$Params = @{
				Path              = "$Path\$Name\$Name.psd1"
				Author            = $Author
				Copyright         = "(c) $(Get-Date -Uformat %Y) $Author. All rights reserved."
				CompanyName       = $CompanyName
				Description       = $Description
				RequiredModules   = $RequiredModules
				FunctionsToExport = '*'
				AliasesToExport   = '*'
				VariablesToExport = '*'
				CmdletsToExport   = '*'
				NestedModules     = "$Name.psm1"
			}
			New-ModuleManifest @Params
			Write-Verbose "Generated $Module manifest at $Path\$Name\$Name.psd1."
	
			Copy-Item $GitIgnore "$Path\$Name\.gitignore"
			Write-Verbose "Copied $GitIgnore to $Path\$Name\.gitignore."
		}
	}
}