Function Close-CommVaultConnection
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QLogout.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd -cs $CommVaultHostName -tk $LoginToken) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QLogout failed with exit code $LASTEXITCODE"
        }

        return $stdout
    }
}
