Function Invoke-CommVaultJobStatus
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName,
        [int]$JobId
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QList.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd job -cs $CommVaultHostName -tk $LoginToken -co isprc -j $JobId) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QList failed with error code $LASTEXITCODE"
        }

        ForEach ($line in $($stdout -split "`n"))
        {
            Write-Verbose $line
        }

        $qlistSatusValues = Get-ValuesFromVisualTextTable -ColumnsDelimiter " -" -LineNumberForColumnsDelimiter 1 -LineNumberForValues 2 -MultiLinesText $stdout

        $jobId = $qlistSatusValues[0].Trim()
        $status = $qlistSatusValues[1].Trim()
        $phase = $qlistSatusValues[2].Trim()
        $failureReason = $qlistSatusValues[3].Trim()
        $completedPercentage = $qlistSatusValues[4].Trim()

        $failureOrPendingReason = $null
        $failureOrPendingReasonIndex = $stdout.IndexOf("Messages for Job failure/pending reasons:")
        if ($failureOrPendingReasonIndex -gt -1)
        {
            $failureOrPendingReason = $stdout.Substring($failureOrPendingReasonIndex)
        }

        return @{JobId = $JobId; Status = $status; Phase = $phase; FailureReason = $failureReason; CompletedPercentage = $completedPercentage; FailureOrPendingReason = $failureOrPendingReason; StatusRaw = $stdout}
    }
}
