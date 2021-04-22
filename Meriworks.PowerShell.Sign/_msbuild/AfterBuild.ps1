param([string] $solutionDir, [string] $projectDir, [string] $targetPath)

#Add powershell statements that should be executed after the build
#test changing timestampUrl
$global:timestampUrl = "http://timestamp.globalsign.com/?signature=sha2"
SignScriptsInFolder (Join-Path $projectDir "nuspec/tools")