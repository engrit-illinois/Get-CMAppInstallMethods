function Get-CMAppInstallMethods {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$Name,
		
		[switch]$ReturnAppsInsteadOfDeploymentTypes,
		
		[int]$Verbosity = 0,
		
		[string]$SiteCode="MP0",
		
		[string]$Provider="sccmcas.ad.uillinois.edu",
		
		[string]$CMPSModulePath="$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
	)
	
	function log {
		param(
			[string]$msg,
			[int]$L,
			[int]$V = 0
		)
		for($i = 0; $i -lt $L; $i += 1) {
			$msg = "    $msg"
		}
		$ts = Get-Date -Format "HH:mm:ss:ffff"
		if($V -le $Verbosity) {
			Write-Host "[$ts] $msg"
		}
	}
	
	function count($array) {
		$count = 0
		if($array) {
			# If we didn't check $array in the above if statement, this would return 1 if $array was $null
			# i.e. @().count = 0, @($null).count = 1
			$count = @($array).count
			# We can't simply do $array.count, because if it's null, that would throw an error due to trying to access a method on a null object
		}
		$count
	}
	
	function addm($property, $value, $object, $adObject = $false) {
		# Shorthand for an annoying common line
		
		if($adObject) {
			# This gets me EVERY FLIPPIN TIME:
			# https://stackoverflow.com/questions/32919541/why-does-add-member-think-every-possible-property-already-exists-on-a-microsoft
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value -Force
		}
		else {
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value
		}
		$object
	}
	
	function Prep-MECM {
		log "Preparing connection to MECM..."
		$initParams = @{}
		if((Get-Module ConfigurationManager) -eq $null) {
			# The ConfigurationManager Powershell module switched filepaths at some point around CB 18##
			# So you may need to modify this to match your local environment
			Import-Module $CMPSModulePath @initParams -Scope Global
		}
		if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
			New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $Provider @initParams
		}
		Set-Location "$($SiteCode):\" @initParams
		log "Done prepping connection to MECM." -L 1
	}
	
	function Get-Apps {
		log "Getting apps..."
		$apps = Get-CMApplication -Fast -Name $Name | Sort LocalizedDisplayName
		$appsCount = count $apps
		log "Found $appsCount matching apps." -L 1
		$apps
	}
	
	function Get-AppDts($apps) {
		log "Getting app deployment types..."
		$apps = $apps | ForEach-Object {
			$app = $_
			log $app.LocalizedDisplayName -L 1 -V 1
			$dts = $app | Get-CMDeploymentType | Sort LocalizedDisplayName
			$dtsCount = count $dts
			log "Found $dtsCount deployment types." -L 2 -V 2
			$dts = $dts | ForEach-Object {
				$dt = $_
				$xml = $dt | Select -ExpandProperty "SDMPackageXML"
				$xmlData = [xml]$xml
				$dt = addm "XmlData" $xmlData $dt
				$dt
			}
			$app = addm "DeploymentTypes" $dts $app
			$app
		}
		$apps
	}
	
	function Get-FlattenedData($apps) {
		log "Flattening data into array of deployment types..."
		$apps | ForEach-Object {
			$app = $_
			$app.DeploymentTypes | ForEach-Object {
				$dt = $_
				
				# Apparently all DT's contain within their XML the info for each other DT as well.
				# So when an app has multiple DTs, if we grab the install/uninstall method for each DT, they will all be an array of all install/uninstall methods for all DTs of the app.
				# It would be too annoying to deal with this legitimately (by associated specific install/uninstall methods to specific DTs.
				# So as a hack, we'll just deal with the possibility that an install/uninstall method could be an array and keep all array members for all DTs, by just joining the members or something.
				$install = $dt.XmlData.AppMgmtDigest.DeploymentType.Installer.InstallAction.Args.Arg | Where { $_.Name -eq "InstallCommandLine" } | Select -ExpandProperty "#text"
				if($install -and ($install.count -gt 1)) { $install = "{" + ($install -join "}, {") + "}" }
				$uninstall = $dt.XmlData.AppMgmtDigest.DeploymentType.Installer.UninstallAction.Args.Arg | Where { $_.Name -eq "InstallCommandLine" } | Select -ExpandProperty "#text"
				if($uninstall -and ($uninstall.count -gt 1)) { $uninstall = "{" + ($uninstall -join "}, {") + "}" }
				
				[PSCustomObject]@{
					Application = $app.LocalizedDisplayName
					DeploymentType = $dt.LocalizedDisplayName
					InstallMethod = $install
					UninstallMethod = $uninstall
				}
			}
		} | Select Application,DeploymentType,InstallMethod,UninstallMethod | Sort Application
	}
	
	function Do-Stuff {
		$myPWD = $pwd.path
		Prep-Mecm
		
		$apps = Get-Apps
		$apps = Get-AppDts $apps
		$dts = Get-FlattenedData $apps
		
		if($ReturnAppsInsteadOfDeploymentTypes) {
			$apps
		}
		else {
			$dts
		}
		
		Set-Location $myPWD
	}
	
	Do-Stuff
	log "EOF"
}