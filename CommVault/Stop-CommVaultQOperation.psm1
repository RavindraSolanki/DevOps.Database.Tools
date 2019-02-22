Function Stop-CommVaultQOperation
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
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QOperation.exe" -Resolve
        Write-Verbose "Executing $cmd"

        & $cmd jobcontrol -cs $CommVaultHostName -tk $LoginToken -j $JobId -o kill

        if ($LASTEXITCODE -ne 0) {
            throw "QOperation failed to end execution of job $JobId with error code $LASTEXITCODE"
        }
    }
}
