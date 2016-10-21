param([string] $solutionDir, [string] $projectDir, [string] $targetPath)

#Add powershell statements that should be executed after the build

SignScriptsInFolder (Join-Path $projectDir "nuspec/tools")