Function Get-RemoteDefaultSqlServerBackupPath
{
    [OutputType([string])]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ExecuteAsUserName,
        [Parameter(Mandatory)][securestring]$ExecuteAsUserPassword,
        [Parameter(Mandatory)][string]$SqlServerComputerName
    )
    Process
    {
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)

        $path = Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ScriptBlock {
            [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
            $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST"

            return $s.Settings.BackupDirectory
        }

        return $path
    }
}