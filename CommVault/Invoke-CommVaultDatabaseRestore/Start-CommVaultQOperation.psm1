Function Start-CommVaultQOperation
{
    [CmdletBinding()]
    Param
    (
        [string]$loginToken,
        [string]$commVaultHostName,
        [string]$xml
    )
    Process
    {
        $tmpFile = [System.IO.Path]::GetTempFileName() + ".xml"

        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QOperation.exe" -Resolve
        Write-Verbose "Executing $cmd"

        Write-Output $xml | Out-File $tmpFile -Encoding utf8
        
        $stdout = (& $cmd execute -cs $commVaultHostName -tk $loginToken -af $tmpFile) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QOperation failed to create new job with error code $LASTEXITCODE.`n$stdout"
        }

        $xmlOutput = [xml]$stdout
        $jobId = $xmlOutput.TMMsg_CreateTaskResp.jobIds.val

        if (!($jobId)) {
            throw "No Job Id returned - $($xmlOutput.OuterXml)"
        }

        return $jobId
    }
}
