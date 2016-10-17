# Meriworks.PowerShell.BuildEvents
When the Meriworks.PowerShell.BuildEvents nuget package is refered to the project, it will scan the _msbuild folder 
for PowerShell scripts and execute them according to their name.

## Actions
We support three actions that can be hooked into; **Build**, **Compile** and **Publish**. 

To hook into an action, decide if you need to hook **Before** or **After** the action.

Name the script accordingly; ie. **BeforeBuild.ps1** will be executed before the build action.

## Configurations
You can also specify a script that only will be triggered during a specific configuration by suffixing the configuration name to the script name.
ie. **AfterBuildRelease.ps1** will only be triggered after a release build. 

## The scripts
The script is a powershell script (.ps1) that will be invoked with four parameters,

    param([string] $solutionDir, [string] $projectDir, [string] $targetPath, [string] $configuration)

where the parameters are as follows.

* $solutionDir refers to the path to the solution folder.
* $projectDir refers to the path to the project folder.
* $targetPath is the path to the resulting output target that the project produces.
* $configuration is the name of the current build configuration
