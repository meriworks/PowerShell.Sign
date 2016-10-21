param (
    [string]$packageVersion = $null,
    [string]$config = "Release"
)
function Die([string]$message, [object[]]$output) {
    if ($output) {
        Write-Output $output
        $message += ". See output above."
    }
    Write-Error $message
    exit 1
}

$rootFolder = Split-Path -parent $script:MyInvocation.MyCommand.Definition

# Myget
$currentVersion = if(Test-Path env:PackageVersion) { Get-Content env:PackageVersion } else { $packageVersion }
if($currentVersion -eq "") {
    Die("Package version cannot be empty")
}

$nugetExe = if(Test-Path Env:NuGet) { Get-Content env:NuGet } else { Join-Path $rootFolder ".nuget\nuget.exe" }
if(-not(Test-Path $nugetExe)){
    Die("Cannot find nuget.exe $nugetExe")
}

. $nugetExe pack "Meriworks.PowerShell.Sign\Meriworks.PowerShell.Sign.nuspec" -version $currentVersion