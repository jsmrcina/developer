# Traces a provider guid with stacks
function global:trace($guid = "ce5fa4ea-ab00-5402-8b76-9f76ac858fb5", $file = "C:\trace.etl", $kernelFile = "C:\kernel.etl", $outFile = "C:\out.etl")
{
    $guidWithStack = "$guid:::'stack'"

    xperf -start trace -on $guidWithStack -f $file
    xperf -on PROC_THREAD+LOADER+PROFILE -stackwalk Profile
    Write-Host -ForegroundColor Yellow "Repro your issue now..."
    pause
    xperf -stop trace
    xperf -d $kernelFile
    xperf -merge $file $kernelFile $outFile

    Write-Host -ForegroundColor Green "Output file is at $outFile"
}