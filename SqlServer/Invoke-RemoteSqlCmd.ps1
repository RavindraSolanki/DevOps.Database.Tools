function Invoke-RemoteSqlCmd
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ExecuteAsUserName,
        [Parameter(Mandatory)][securestring]$ExecuteAsUserPassword,
        [Parameter(Mandatory)][string]$SqlServerComputerName,
        [Parameter(Mandatory)][string]$DatabaseName,
        [Parameter(Mandatory)][string]$SqlFilePath
    )
    Process
    {
        Write-Host "Executing sqlfile '$SqlFilePath'"
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)
        $inputFileContent = Get-Content -Path $SqlFilePath -Raw

        Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ArgumentList $inputFileContent, $DatabaseName -ScriptBlock {
            Param
            (
                [string]$SqlScript,
                [string]$DbName
            )

            try
            {
                $tmpSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
                $SqlScript | Out-File -Append -FilePath $tmpSqlFile

                Invoke-Sqlcmd -InputFile $tmpSqlFile -database $DbName
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