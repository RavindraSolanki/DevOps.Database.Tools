Function Wait-CommVaultJobCompletion
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName,
        [string]$JobId,
        [int]$PollTime = 60,
        [datetime]$TimeoutAfter = [datetime]::MaxValue
    )
    Process
    {
        $jobStatus = Invoke-CommVaultJobStatus -LoginToken $LoginToken -CommVaultHostName $CommVaultHostName -JobId $JobId

        while ([string]::IsNullOrWhiteSpace($jobStatus.Status) -eq $true -or ($jobStatus.Status -ne "Completed" -and $jobStatus.Status -ne "Failed" -and $jobStatus.Status -ne "Killed"))
        {
            if ([string]::IsNullOrWhiteSpace($jobStatus.FailureOrPendingReason) -eq $false)
            {
                ForEach ($line in $jobStatus.FailureOrPendingReason -split "`n")
                {
                    Write-Host $line
                }

                if ($TimeoutAfter -eq [datetime]::MaxValue)
                {
                    $TimeoutAfter = [datetime]::UtcNow.AddMinutes(20)
                }
            }

            if ([datetime]::UtcNow -gt $TimeoutAfter)
            {
                throw "Timeout while waiting for job to finish after failure/pending reasons message"
            }

            Write-Host "$(Get-Date) Waiting for job '$($jobStatus.JobId)', $($jobStatus.CompletedPercentage)% completed ..."

            Start-Sleep -Seconds $PollTime

            $jobStatus = Invoke-CommVaultJobStatus -LoginToken $LoginToken -CommVaultHostName $CommVaultHostName -JobId $JobId
        }

        return $jobStatus
    }
}
