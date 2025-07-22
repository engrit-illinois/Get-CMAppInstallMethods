# Summary

Module to pull the "Install program" and "Uninstall program" fields from all deployment types of all matching MECM applications

# Usage

1. Download `Get-CMAppInstallMethods.psm1` to the appropriate subdirectory of your PowerShell [modules directory](https://github.com/engrit-illinois/how-to-install-a-custom-powershell-module).
2. Run it, using the examples and documentation provided below.

# Examples
For large queries it's recommended to capture the output as a CSV:
```powershell
Get-CMAppInstallMethods -Name "UIUC-ENGR-*" | Export-Csv -Path "c:\get-cmappinstallmethods.csv" -Encoding "Ascii" -NoTypeInformation
```

# Parameters

### -Name
Required string.  
A wildcard query string against which to match applications.  
Only matching applications are polled and returned.  

### -ReturnAppsInsteadOfDeploymentTypes
Optional switch.  
Normally the module returns a flattened array of deployment types and their associated apps and install/uninstall methods.  
When specified, an array of applications and all the gathered deployment type info retrieved is returned instead.  

### -Verbosity
Optional integer.  
Default is `0`.  
Higher values cause logging to be more and more verbose.  

### -SiteCode
Optional string. Recommend leaving default.  
The site code of the MECM site to connect to.  
Default is `MP0`.  

### -Provider
Optional string. Recommend leaving default.  
The SMS provider machine name.  
Default is `sccmcas.ad.uillinois.edu`.  

### -CMPSModulePath
Optional string. Recommend leaving default.  
The path to the ConfigurationManager Powershell module installed on the local machine (as part of the admin console).  
Default is `$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1`.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
