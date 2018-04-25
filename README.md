# Meriworks.PowerShell.Sign
Adds PowerShell functions to allow you to sign scripts and files using a code signing certificate.

Is an [Extension Module](https://github.com/meriworks/PowerShell.BuildEvents#Extension_Modules) to the [Meriworks.PowerShell.BuildEvents](https://github.com/meriworks/PowerShell.BuildEvents) .

* [Requirements](#requirements)
* [Documentation](#documentation)
* [License](#license)
* [Author](#author)
* [Changelog](#changelog)

<a name="requirements"></a>
## Requirements
To sign your files you need to have signtool.exe installed. The easiest way to install it and allow the Meriworks.PowerShell.Sign scripts to find it is to install the [Windows Sdk](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk).

<a name="documentation"></a>
## Documentation

### Signing items
When including the NuGet package to your Visual Studio project, the following PowerShell functions is automatically available in the [BuildEvent scripts](https://github.com/meriworks/PowerShell.BuildEvents#documentation).

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
Since version 6, this file is now included automatically and the PowerShell dotting is now obsolete and the previous initialization line needs to be removed from the scripts.

> ~~. (Join-Path $projectDir "_msbuild/Meriworks.PowerShell.Sign/Functions.ps1")~~

#### SignTool Error: Signtool requires CAPICOM version 2.1.0.1 or higher
In case you get the error message above when invoking the scripts, then follow the instructions below

* Download and install Capicom 2.1.0.2 <http://www.microsoft.com/sv-se/download/details.aspx?id=25281>
* Copy capicom.dll from `C:\Program Files (x86)\Microsoft CAPICOM 2.1.0.2\lib\X86\` to `C:\Windows\SysWOW64\`
* Start a cmd prompt in admin mode and run the following commands
		
		cd C:\Windows\SysWOW64
		Regsvr32 capicom.dll

<a name="license"></a>
## License
Licensed using the [MIT License](LICENSE.md).

<a name="author"></a>
## Author
Developed by [Dan Händevik](mailto:dan@meriworks.se), [Meriworks](http://www.meriworks.se).

<a name="changelog"></a>
## Changelog

### v6.0.4 - 2018-04-25
* Added error handling if singing a script fails

### v6.0.3 - 2018-04-19
* Fixed an issue with expiration date

### v6.0.2 - 2018-04-19
* Now supports Windows 10 Sdk paths for signtool.exe

### v6.0.1 - 2017-09-25
* Fixed issue where the path to signtool.exe was incorrectly calculated


### v6.0.0 - 2016-10-21
* [Inlining of Function.ps1 is no longer supported](#cannot_find_functions.ps1_file)
* Removed unused dll from nupkg file
* Removed scripts and readme from project

### v5.0.1 - 2016-10-17
* Minor changes in nuspec, license and documentation

### v5.0.0 - 2016-10-17
* Initial release

