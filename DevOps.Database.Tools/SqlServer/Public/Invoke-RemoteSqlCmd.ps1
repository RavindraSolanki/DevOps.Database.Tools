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
        [string[]]$SqlVariables = $null,
        [string]$QueryTimeout = 30
    )
    Process
    {
        Write-Host "Executing sqlfile '$SqlFilePath'"
        $credential = New-Object System.Management.Automation.PSCredential ($ExecuteAsUserName, $ExecuteAsUserPassword)
        $inputFileContent = Get-Content -Path $SqlFilePath -Raw

        Invoke-Command -ComputerName $SqlServerComputerName -Credential $credential -ArgumentList $inputFileContent, $DatabaseName, $SqlVariables, $QueryTimeout -ScriptBlock {
            Param
            (
                [string]$SqlScript,
                [string]$DbName,
                [string[]]$Variables,
                [int]$Timeout
            )

            try
            {
                $tmpSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
                $SqlScript | Out-File -Append -FilePath $tmpSqlFile

                if ($null -eq $Variables)
                {
                    Invoke-Sqlcmd -InputFile $tmpSqlFile -Database $DbName -QueryTimeout $Timeout
                }
                else
                {
                    Invoke-Sqlcmd -InputFile $tmpSqlFile -Database $DbName -Variable $Variables -QueryTimeout $Timeout
                }
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