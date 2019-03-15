@{
    # Grab some modules without depending on PowerShellGet
    psake         = 'latest'
    PSDeploy      = 'latest'
    BuildHelpers  = 'latest'
    Pester        = @{
        Version = 'latest'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
}