function Invoke-RemoteBackupSqlDatabase
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ExecuteAsUserName,
        [Parameter(Mandatory)][securestring]$ExecuteAsUserPassword,
        [Parameter(Mandatory)][string]$SqlServerComputerName,
        [Parameter(Mandatory)][string]$DatabaseName,
        [string]$BackupFilePath
    )
    Process
    {
        Write-Host "Creating backup of $SqlServerComputerName '$DatabaseName' and save to $BackupFilePath"
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)

        Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ArgumentList $DatabaseName, $BackupFilePath -ScriptBlock {
            Param
            (
                [string]$DbName,
                [string]$BackupFile
            )

            if (Test-Path -Path $BackupFile -PathType Leaf)
            {
                Write-Host "A previous backup file exist, removing $BackupFile"
                Remove-Item -Path $BackupFile
            }
			
			if ($BackupFilePath -eq $null)
			{
				Backup-SqlDatabase -ServerInstance localhost -Database $DbName
			}
			else
			{
				Backup-SqlDatabase -ServerInstance localhost -Database $DbName -BackupFile $BackupFile
			}
        }
    }
}