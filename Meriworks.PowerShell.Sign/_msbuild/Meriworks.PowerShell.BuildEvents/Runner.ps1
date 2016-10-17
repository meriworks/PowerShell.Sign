param([string] $name, [string] $solutionDir, [string] $projectDir, [string] $targetPath, [string] $configuration)

##Add errorhandling
trap {"Error in $name in $configuration build: $($_.InvocationInfo.PositionMessage)`r`n$($_.Exception.Message)"; exit 1; continue}

Write-Host "Information: Running $name in $configuration build"

$paths = @((Join-Path $projectDir "_msbuild/$name$configuration.ps1"), (Join-Path $projectDir "_msbuild/$name.ps1"))
foreach($path in $paths) {
	if(!(Test-Path $path)) {
		continue
	}
	Write-Host "Running PowerShell $path"
	$args = @("`"$solutionDir`"", "`"$projectDir`"", "`"$targetPath`"", "`"$configuration`"")
	Invoke-expression "& `"$path`" $args" 
}
