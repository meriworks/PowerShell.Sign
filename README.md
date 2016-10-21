# Meriworks.PowerShell.Sign
Adds PowerShell functions to allow you to sign scripts and files using a code signing certificate.

Is an [Extension Module](https://github.com/meriworks/PowerShell.BuildEvents#Extension_Modules) to the [Meriworks.PowerShell.BuildEvents](https://github.com/meriworks/PowerShell.BuildEvents) .

* [License](#license)
* [Author](#author)
* [Changelog](#changelog)
* [Documentation](#documentation)

<a name="license"></a>
## License
Project is licensed using the [MIT License](LICENSE.md).

<a name="author"></a>
## Author
Package is developed by [Dan Händevik](mailto:dan@meriworks.se), [Meriworks](http://www.meriworks.se).

<a name="changelog"></a>
## Changelog

### v6.0.0 - 2016-10-21
* [Inlining of Function.ps1 is no longer supported](#cannot_find_functions.ps1_file)
* Removed unused dll from nupkg file
* Removed scripts and readme from project

### v5.0.1 - 2016-10-17
* Minor changes in nuspec, license and documentation

### v5.0.0 - 2016-10-17
* Initial release

<a name="documentation"></a>
## Documentation

### Signing items
When including the nuget package to your Visual Studio project, the following PowerShell functions is automatically available in the [BuildEvent scripts](https://github.com/meriworks/PowerShell.BuildEvents#documentation).

#### SignScript
This method will sign a ps1 script using the **Set-Authenticode** command if needed.

Usage:

    SignScript (join-path $projectDir "nuspec/tools/install.ps1")
 
#### SignScriptsInFolder
This method works in the same way as **SignScript** but will sign all files in a given folder

Usage:

    SignScriptsInFolder (join-path $projectDir "nuspec/tools")

_Will sign all *.ps1 and *.psm1 files._

#### SignMsi
This method will sign an msi using the **signtool.exe** command. 

Usage:

    $file = "path/to/myprogram.msi"
    SignMsi "www.mysite.com" "My program v1.0.0 setup" $file

### Troubleshooting

<a name="cannot_find_functions.ps1_file"></a>
#### Cannot find Functions.ps1 file
Since version 6, this file is now included automatically and the PowerShell dotting is now obsolete and the previos initialization line needs to be removed from the scripts.

> ~~. (Join-Path $projectDir "_msbuild/Meriworks.PowerShell.Sign/Functions.ps1")~~

#### SignTool Error: Signtool requires CAPICOM version 2.1.0.1 or higher
In case you get the error message above when invoking the scripts, then follow the instructions below

* Download and install Capicom 2.1.0.2 <http://www.microsoft.com/sv-se/download/details.aspx?id=25281>
* Copty capicom.dll from `C:\Program Files (x86)\Microsoft CAPICOM 2.1.0.2\lib\X86\` to `C:\Windows\SysWOW64\`
* Start a cmd prompt in admin mode and run the following commands
		
		cd C:\Windows\SysWOW64
		Regsvr32 capicom.dll
