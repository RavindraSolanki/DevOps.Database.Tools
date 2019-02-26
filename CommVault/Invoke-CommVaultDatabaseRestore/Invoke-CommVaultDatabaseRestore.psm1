# Utility functions are placed in their own files, hence we're 'dot sourcing' them from this module
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }

Function Invoke-CommVaultDatabaseRestore
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$CommVaultUsername,
        [Parameter(Mandatory)]
        [string]$CommVaultEncryptedPassword,
        [Parameter(Mandatory)]
        [string]$CommVaultHostName,
        [Parameter(Mandatory)]
        [string]$CommVaultClientName,
        [Parameter(Mandatory)]
        [string]$SourceClientName,
        [Parameter(Mandatory)]
        [string]$SourceInstanceName,
        [Parameter(Mandatory)]
        [string]$SourceDatabaseName,
        [Parameter(Mandatory)]
        [string]$DestinationClientName,
        [Parameter(Mandatory)]
        [string]$DestinationInstanceName,
        [Parameter(Mandatory)]
        [string]$DestinationDatabaseName,
        [Parameter(Mandatory)]
        [string]$JsonDatabaseFilesConfiguration,
        [string]$BackupSetName = 'defaultBackupSet',
        [string]$ToTimeValue = (Get-Date -format "yyyy-MM-dd HH:mm:ss")
    )
    Process
    {
        Write-Host "Starting CommVault database Restore"

        $CommVaultClientName = $CommVaultClientName -Replace '[\\].*'
        $SourceClientName = $SourceClientName -Replace '[\\].*'
        $DestinationClientName = $DestinationClientName -Replace '[\\].*'

        Write-Verbose "CommVaultUsername: $CommVaultUsername"
        Write-Verbose "CommVaultHostName: $CommVaultHostName"
        Write-Verbose "CommVaultClientName: $CommVaultClientName"
        Write-Verbose "SourceClientName: $SourceClientName"
        Write-Verbose "SourceInstanceName: $SourceInstanceName"
        Write-Verbose "SourceDatabaseName: $SourceDatabaseName"
        Write-Verbose "DestinationClientName: $DestinationClientName"
        Write-Verbose "DestinationInstanceName: $DestinationInstanceName"
        Write-Verbose "DestinationDatabaseName: $DestinationDatabaseName"
        Write-Verbose "BackupSetName: $BackupsetName"
        Write-Verbose "ToTimeValue: $ToTimeValue"
        Write-Verbose "JsonDatabaseFilesConfiguration: `n$JsonDatabaseFilesConfiguration"

        $xml = Get-CommVaultRestoreDatabaseXml `
                -SourceClientName $SourceClientName `
                -SourceInstanceName $SourceInstanceName `
                -SourceDatabaseName $SourceDatabaseName `
                -DestinationClientName $DestinationClientName `
                -DestinationInstanceName $DestinationInstanceName `
                -DestinationDatabaseName $DestinationDatabaseName `
                -Devices $JsonDatabaseFilesConfiguration `
                -BackupsetName $BackupsetName `
                -ToTimeValue $ToTimeValue

        Write-Verbose "CommVault $xml"
    
        Write-Verbose 'Requesting CommVault login token'
        $loginToken = Open-CommVaultConnection `
                        -Username $CommVaultUsername `
                        -EncryptedPassword $CommVaultEncryptedPassword `
                        -CommVaultHostName $CommVaultHostName `
                        -CommVaultClientName $CommVaultClientName
        
        Try {

            Write-Verbose 'Creating CommVault database restore job'

            $jobId = Start-CommVaultQOperation `
                        -LoginToken $loginToken `
                        -CommVaultHostName $CommVaultHostName `
                        -Xml $xml
            
            if (!($jobId)) {
                throw 'Error: failed to submit CommVault database restore job'
            }

            Write-Host "CommVault job created with JobId: $jobId"
            
            $jobStatus = Wait-CommVaultJobCompletion `
                            -LoginToken $loginToken `
                            -CommVaultHostName $CommVaultHostName `
                            -JobId $jobId

            if ($jobStatus.FailureReason.length -gt 0) {
                Write-Error "An error has occured: $($jobStatus.FailureReason)`r`n$($jobStatus.StatusRaw)"

                Write-Verbose "Job with id '$jobId' is being killed"
                Stop-CommVaultQOperation `
                    -LoginToken $loginToken `
                    -CommVaultHostName $commVaultHostName `
                    -JobId $jobId

                throw "CommVault database restore job '$jobId' failed"
            }

            Write-Host 'CommVault database restore job '$jobId' successfully completed'
        }
        Finally {
            Write-Host "Releasing CommVault token"
            
            Close-CommVaultConnection -loginToken $loginToken -commVaultHostName $CommVaultHostName

            Write-Host "CommVault token released"
        }
    }
}
