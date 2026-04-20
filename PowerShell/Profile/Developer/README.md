# Notes on Set-BinlogEnvironment

## MSBuild evaluation

Invoking MSBuild for evaluation only (getProperty/getItem) does not auto-generate a binlog.
Adding the -bl switch on the command line works, but doesn't help with Visual Studio.

We can capture MSBuild events separately, but we need to do this for both the .NET and .NET Framework
version of MSBuild, because Visual Studio uses the latter. That requires an ETW listener instead of an
EventPipe listener.

- MSBuild event source name: `Microsoft-Build`, GUID: `{d44a2098-821f-5808-4cea-1e24e982ca37}`
- Create a trace listener as admin:
  ```
  logman create trace 'msbuild-trace' -o 'logfile.etl' -m start stop -p '{d44a2098-821f-5808-4cea-1e24e982ca37}' 1 5 -bs 1024 -ow
  ```
- Manually start/stop the trace (no admin required):
  ```
  logman start msbuild.trace
  logman stop msbuild.trace
  ```
- Use [PerfView](https://github.com/microsoft/perfview) to view the trace. The Windows Event Viewer or Visual Studio won't display the payloads correctly.
  ```
  perfview -AcceptEULA logfile.etl
  ```

## TODO

The trace duplicates a lot of information already more detailed in the binlog. We need a way to filter out those events.

## Resources

- https://github.com/dotnet/msbuild/blob/main/documentation/wiki/MSBuild-Environment-Variables.md
- https://github.com/dotnet/msbuild/blob/main/documentation/Property-tracking-capabilities.md
- https://github.com/dotnet/msbuild/blob/main/src/Framework/Traits.cs
- https://github.com/dotnet/msbuild/blob/main/src/Build/BackEnd/BuildManager/BuildParameters.cs
- https://github.com/dotnet/msbuild/blob/main/src/Build/Logging/BinaryLogger/BinaryLogger.cs
- https://github.com/dotnet/msbuild/blob/main/src/Framework/MSBuildEventSource.cs
