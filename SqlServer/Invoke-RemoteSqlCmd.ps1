function Invoke-RemoteSqlCmd
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ExecuteAsUserName,
        [Parameter(Mandatory)][securestring]$ExecuteAsUserPassword,
        [Parameter(Mandatory)][string]$SqlServerComputerName,
        [Parameter(Mandatory)][string]$DatabaseName,
        [Parameter(Mandatory)][string]$SqlFilePath,
        [string]$QueryTimeout = 30
    )
    Process
    {
        Write-Host "Executing sqlfile '$SqlFilePath'"
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)
        $inputFileContent = Get-Content -Path $SqlFilePath -Raw

        Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ArgumentList $inputFileContent, $DatabaseName, $QueryTimeout -ScriptBlock {
            Param
            (
                [string]$SqlScript,
                [string]$DbName,
                [int]$Timeout
            )

            try
            {
                $tmpSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
                $SqlScript | Out-File -Append -FilePath $tmpSqlFile

                Invoke-Sqlcmd -InputFile $tmpSqlFile -Database $DbName -QueryTimeout $Timeout
            }
            finally
            {
                if (Test-Path $tmpSqlFile)
                {
                    Remove-Item -Path $tmpSqlFile
                }
            }
        }
    }
}