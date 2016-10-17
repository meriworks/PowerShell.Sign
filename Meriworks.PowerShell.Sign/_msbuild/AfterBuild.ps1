param([string] $solutionDir, [string] $projectDir, [string] $targetPath)

#Add powershell statements that should be executed after the build

. (Join-Path $projectDir "nuspec/content/_msbuild/Meriworks.PowerShell.Sign/Functions.ps1")

SignScript (Join-Path $projectDir "nuspec/content/_msbuild/Meriworks.PowerShell.Sign/Functions.ps1")
SignScriptsInFolder (Join-Path $projectDir "nuspec/tools")