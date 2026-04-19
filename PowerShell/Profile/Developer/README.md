# Notes on Set-BinlogEnvironment

## MSBuild evaluation

Invoking MSBuild for evaluation only (getProperty/getItem) does not auto-generate a binlog.
Adding the -bl switch works, but doesn't help with VStudio.

MSBuild has an EventSource named 'Microsoft-Build'. The following settings enable tracing
for dotnet msbuild, but don't produce events in VStudio:

```pwsh
$env:DOTNET_EnableEventPipe = 1
$env:DOTNET_EventPipeConfig = 'Microsoft-Build:1:4'
$env:DOTNET_EventPipeOutputPath = '<fully-qualified-filepath>'
$env:DOTNET_EventPipeRundown = 0 # Needed to supress unwanted events
$env:DOTNET_EventPipeEnableStackwalk = 0 # Needed to exclude stacks.
```

## Resources

- https://github.com/dotnet/msbuild/blob/main/documentation/wiki/MSBuild-Environment-Variables.md
- https://github.com/dotnet/msbuild/blob/main/documentation/Property-tracking-capabilities.md
- https://github.com/dotnet/msbuild/blob/main/src/Framework/Traits.cs
- https://github.com/dotnet/msbuild/blob/main/src/Build/BackEnd/BuildManager/BuildParameters.cs
- https://github.com/dotnet/msbuild/blob/main/src/Build/Logging/BinaryLogger/BinaryLogger.cs
- https://github.com/dotnet/msbuild/blob/main/src/Framework/MSBuildEventSource.cs
