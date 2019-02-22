Function Get-CommVaultBasePath
{
    [CmdletBinding()]
    Param()
    Process
    {
        $commVaultLookupBasePaths = @("C:\Program Files\CommVault\Simpana\Base\", "C:\Program Files\CommVault\ContentStore\Base\", "C:\Program Files\CommVault\ContentStore2\Base\")

        $commVaultBasePath = $env:CV_Instance001
        if ([string]::IsNullOrWhiteSpace($commVaultBasePath) -or (Test-Path -Path $commVaultBasePath -PathType Container) -eq $false)
        {
            $commVaultLookupBasePaths | ForEach-Object {
                if (Test-Path -Path $_  -PathType Container) {
                    $commVaultBasePath = $_
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($commVaultBasePath)) {
            throw "CommVault seems to not be installed"
        }

        return $commVaultBasePath
    }
}
