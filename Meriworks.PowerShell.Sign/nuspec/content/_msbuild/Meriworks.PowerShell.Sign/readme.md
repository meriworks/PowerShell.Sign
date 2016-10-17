# Meriworks.PowerShell.Sign
The sign library adds a PowerShell script for signing scripts, exe, dll and msi files.

## Signing items
To use the PowerShell scripts, first include them in your PowerShell script using the statement below

. (Join-Path $projectDir "_msbuild/Meriworks.PowerShell.Sign/Functions.ps1")

### SignScript
This method will sign a ps1 script using the **Set-Authenticode** command if needed.

Usage:

    SignScript (join-path $projectDir "nuspec/tools/install.ps1")
 
### SignScriptsInFolder
This method works in the same way as **SignScript** but will sign all files in a given folder

Usage:

    SignScriptsInFolder (join-path $projectDir "nuspec/tools")

_Will sign all *.ps1 and *.psm1 files._

### SignMsi
This method will sign an msi using the **signtool.exe** command. 

Usage:

    $file = "path/to/myprogram.msi"
    SignMsi "www.mysite.com" "My program v1.0.0 setup" $file

## Troubleshooting

### SignTool Error: Signtool requires CAPICOM version 2.1.0.1 or higher
In case you get the error message above when invoking the scripts, then follow the instructions below

* Download and install Capicom 2.1.0.2 <http://www.microsoft.com/sv-se/download/details.aspx?id=25281>
* Copty capicom.dll from C:\Program Files (x86)\Microsoft CAPICOM 2.1.0.2\lib\X86\ to C:\Windows\SysWOW64\
* Start a cmd prompt in admin mode and run the following commands
  * cd C:\Windows\SysWOW64
  * Regsvr32 capicom.dll
