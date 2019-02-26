Function Open-CommVaultConnection
{
    [CmdletBinding()]
    Param
    (
        [string]$Username,
        [string]$EncryptedPassword,
        [string]$CommVaultHostName,
        [string]$CommVaultClientName
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QLogin.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd -u $Username -ps $EncryptedPassword -cs $CommVaultHostName -csn $CommVaultClientName -gt) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QLogin failed with exit code $LASTEXITCODE"
        }

        return $stdout
    }
}
