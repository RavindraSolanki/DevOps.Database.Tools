Function Get-DefaultSqlServerBackupPath
{
    [OutputType([string])]
    [CmdletBinding()]
    Param()
    Process
    {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
        $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "LOCALHOST" 

        return $s.Settings.BackupDirectory
    }
}