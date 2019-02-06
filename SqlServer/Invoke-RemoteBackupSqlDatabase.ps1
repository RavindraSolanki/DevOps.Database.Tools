function Invoke-RemoteBackupSqlDatabase
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ExecuteAsUserName,
        [Parameter(Mandatory)][securestring]$ExecuteAsUserPassword,
        [Parameter(Mandatory)][string]$SqlServerComputerName,
        [Parameter(Mandatory)][string]$DatabaseName,
        [Parameter(Mandatory)][string]$BackupFilePath
    )
    Process
    {
        Write-Host "Creating backup of $SqlServerComputerName '$DatabaseName'"
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)

        Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ArgumentList $DatabaseName, $BackupFilePath -ScriptBlock {
            Param
            (
                [string]$DbName,
                [string]$BackupFile
            )

            Backup-SqlDatabase -ServerInstance localhost -Database $DbName -BackupFile $BackupFile
        }
    }
}