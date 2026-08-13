# Traces a provider guid with stacks (Windows only, requires the WPT xperf tool)
function global:trace($guid = "ce5fa4ea-ab00-5402-8b76-9f76ac858fb5",
                      $file = (Join-Path ([System.IO.Path]::GetTempPath()) "trace.etl"),
                      $kernelFile = (Join-Path ([System.IO.Path]::GetTempPath()) "kernel.etl"),
                      $outFile = (Join-Path ([System.IO.Path]::GetTempPath()) "out.etl"))
{
    if (-not (Test-WindowsOnly "ETW tracing with xperf"))
    {
        Write-Host -ForegroundColor Yellow "On Linux, use 'perf record' or LTTng instead."
        return
    }

    if (-not (checktool "xperf"))
    {
        return
    }

    $guidWithStack = "$guid:::'stack'"

    xperf -start trace -on $guidWithStack -f $file
    xperf -on PROC_THREAD+LOADER -f $kernelFile
    Write-Host -ForegroundColor Yellow "Repro your issue now..."
    pause
    xperf -stop
    xperf -stop trace
    xperf -merge $file $kernelFile $outFile

    Write-Host -ForegroundColor Green "Output file is at $outFile"
}
