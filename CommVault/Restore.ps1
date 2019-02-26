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
Function Open-CommVaultConnection
{
    [CmdletBinding()]
    Param
    (
        [string]$Username,
        [string]$EncryptedPassword,
        [string]$CommVaultHostName,
        [string]$CommVaultClientName
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QLogin.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd -u $Username -ps $EncryptedPassword -cs $CommVaultHostName -csn $CommVaultClientName -gt) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QLogin failed with exit code $LASTEXITCODE"
        }

        return $stdout
    }
}
Function Close-CommVaultConnection
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QLogout.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd -cs $CommVaultHostName -tk $LoginToken) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QLogout failed with exit code $LASTEXITCODE"
        }

        return $stdout
    }
}
Function Stop-CommVaultQOperation
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName,
        [int]$JobId
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QOperation.exe" -Resolve
        Write-Verbose "Executing $cmd"

        & $cmd jobcontrol -cs $CommVaultHostName -tk $LoginToken -j $JobId -o kill

        if ($LASTEXITCODE -ne 0) {
            throw "QOperation failed to end execution of job $JobId with error code $LASTEXITCODE"
        }
    }
}
Function Start-CommVaultQOperation
{
    [CmdletBinding()]
    Param
    (
        [string]$loginToken,
        [string]$commVaultHostName,
        [string]$xml
    )
    Process
    {
        $tmpFile = [System.IO.Path]::GetTempFileName() + ".xml"

        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QOperation.exe" -Resolve
        Write-Verbose "Executing $cmd"

        Write-Output $xml | Out-File $tmpFile -Encoding utf8
        
        $stdout = (& $cmd execute -cs $commVaultHostName -tk $loginToken -af $tmpFile) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QOperation failed to create new job with error code $LASTEXITCODE.`n$stdout"
        }

        $xmlOutput = [xml]$stdout
        $jobId = $xmlOutput.TMMsg_CreateTaskResp.jobIds.val

        if (!($jobId)) {
            throw "No Job Id returned - $($xmlOutput.OuterXml)"
        }

        return $jobId
    }
}

Function Wait-CommVaultJobCompletion
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName,
        [string]$JobId,
        [int]$PollTime = 60
    )
    Process
    {
        $jobStatus = Invoke-CommVaultJobStatus -LoginToken $LoginToken -CommVaultHostName $CommVaultHostName -JobId $JobId

        while ($jobStatus.Status -ne "Completed" -and $jobStatus.Status -ne "Failed" -and $jobStatus.Status -ne "Killed" -and $null -ne $jobStatus.Status) {

            Write-Host "$(Get-Date) Waiting for job '$($jobStatus.JobId)', $($jobStatus.CompletedPercentage)% completed ..."

            Start-Sleep -Seconds $PollTime

            $jobStatus = Invoke-CommVaultJobStatus -LoginToken $LoginToken -CommVaultHostName $CommVaultHostName -JobId $JobId
        }

        return $jobStatus
    }
}
Function Invoke-CommVaultJobStatus
{
    [CmdletBinding()]
    Param
    (
        [string]$LoginToken,
        [string]$CommVaultHostName,
        [int]$JobId
    )
    Process
    {
        $cmd = Join-Path -Path (Get-CommVaultBasePath) -ChildPath "QList.exe" -Resolve
        Write-Verbose "Executing $cmd"

        $stdout = (& $cmd job -cs $CommVaultHostName -tk $LoginToken -co isprc -j $JobId) | Out-String

        if ($LASTEXITCODE -ne 0) {
            throw "QList failed with error code $LASTEXITCODE"
        }

        ForEach ($line in $($stdout -split "`n"))
        {
            Write-Verbose $line
        }

        $qlistSatusValues = Get-ValuesFromVisualTextTable -ColumnsDelimiter " -" -LineNumberForColumnsDelimiter 1 -LineNumberForValues 2 -MultiLinesText $stdout

        $jobId = $qlistSatusValues[0].Trim()
        $status = $qlistSatusValues[1].Trim()
        $phase = $qlistSatusValues[2].Trim()
        $failureReason = $qlistSatusValues[3].Trim()
        $completedPercentage = $qlistSatusValues[4].Trim()

        return @{JobId = $JobId; Status = $status; Phase = $phase; FailureReason = $failureReason; CompletedPercentage = $completedPercentage; StatusRaw = $stdout}
    }
}

Function Get-ValuesFromVisualTextTable
{
    [OutputType([string[]])]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)][string]$ColumnsDelimiter,
        [Parameter(Mandatory)][string]$LineNumberForColumnsDelimiter,
        [Parameter(Mandatory)][string]$LineNumberForValues,
        [Parameter(Mandatory)][string]$MultiLinesText
    )
    Process
    {
        Write-Verbose "ColumnsDelimiter: $ColumnsDelimiter"
        Write-Verbose "LineNumberForColumnsDelimiter: $LineNumberForColumnsDelimiter"
        Write-Verbose "LineNumberForValues: $LineNumberForValues"
        Write-Verbose "MultiLinesText:"
        ForEach ($line in $($MultiLinesText -split "`n"))
        {
            Write-Verbose $line
        }

        $multiLinesTextArray = $MultiLinesText.Split("`n")
        $lineWithColumnsDelimiter = $multiLinesTextArray[$LineNumberForColumnsDelimiter]
        Write-Verbose "LineWithColumnsDelimiter: $lineWithColumnsDelimiter"
        $lineWithValuesInColumns = $multiLinesTextArray[$LineNumberForValues]
        Write-Verbose "LineWithValuesInColumns: $lineWithValuesInColumns"

        $columnsStartIndexes = [int[]]@()
        $currentColumnStartIndexInLine = 0
        do
        {
            $columnsStartIndexes += $currentColumnStartIndexInLine
            $currentColumnStartIndexInLine = $lineWithColumnsDelimiter.IndexOf($ColumnsDelimiter, $currentColumnStartIndexInLine) + ($ColumnsDelimiter.Length - 1)

        } while ($currentColumnStartIndexInLine -gt 0)

        $valuesInColumnOrder = [string[]]@()
        $numberOfColumns = $columnsStartIndexes.Count
        For ($index = 0 ; $index -lt $numberOfColumns ; $index++)
        {
            $nextColumnIndex = $index + 1
            if ($nextColumnIndex -lt $numberOfColumns)
            {
                $length = $columnsStartIndexes[$nextColumnIndex] - $columnsStartIndexes[$index]
            }
            else
            {
                $length = $lineWithValuesInColumns.Length - $columnsStartIndexes[$index]
            }
            $value = $lineWithValuesInColumns.Substring($columnsStartIndexes[$index], $length)
            $valuesInColumnOrder += $value
        }

        return $valuesInColumnOrder
    }
}

Function Get-CommVaultRestoreDatabaseXml
{
    [CmdletBinding()]
    Param
    (
        [string]$SourceClientName,
        [string]$SourceInstanceName,
        [string]$SourceDatabaseName,
        [string]$DestinationClientName,
        [string]$DestinationInstanceName,
        [string]$DestinationDatabaseName,
        [string]$Devices,
        [string]$BackupsetName,
        [string]$ToTimeValue
    )
    Process
    {
        if ($SourceInstanceName.ToLower() -eq $DestinationInstanceName.ToLower() -and $SourceDatabaseName.ToLower() -eq $DestinationDatabaseName.ToLower()) {
            throw "Source and destination can't be the same"
        }

        $jsonDataFilesConfig = ConvertFrom-Json -InputObject $Devices

        $devicesString = ""
        $jsonDataFilesConfig | ForEach-Object {
            Write-Verbose "Device mapping used LogicalName '$($_.LogicalName)', SourceDatabaseName '$($_.SourceDatabaseName)', SourceDatabasePath '$($_.SourceDatabasePath)', DestinationDatabaseName '$($_.DestinationDatabaseName)', DestinationDatabasePath '$($_.DestinationDatabasePath)'"
            $devicesString += "<device>|$($_.SourceDatabaseName)|#12!$($_.DestinationDatabaseName)|#12!$($_.LogicalName)|#12!$($_.DestinationDatabasePath)|#12!$($_.SourceDatabasePath)</device>"
        }

        $x = @"
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<TMMsg_CreateTaskReq>

  <taskInfo>
    <associations>
      <appName>SQL Server</appName>
      <backupsetName>$BackupsetName</backupsetName>
      <clientName>$SourceClientName</clientName>
      <instanceName>$SourceInstanceName</instanceName>
      <subclientName></subclientName>
    </associations>
    <subTasks>
      <options>
        <restoreOptions>
          <browseOption>
            <backupset>
              <backupsetName>$BackupsetName</backupsetName>
              <clientName>$SourceClientName</clientName>
            </backupset>
            <commCellId>2</commCellId>
            <listMedia>false</listMedia>
            <mediaOption>
              <copyPrecedence>
                <copyPrecedenceApplicable>false</copyPrecedenceApplicable>
              </copyPrecedence>
              <drivePool/>
              <library/>
              <mediaAgent/>
            </mediaOption>
            <noImage>false</noImage>
            <timeRange>
              <toTimeValue>$ToTimeValue</toTimeValue>
            </timeRange>
            <timeZone>
              <TimeZoneName>(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna</TimeZoneName>
            </timeZone>
            <useExactIndex>false</useExactIndex>
          </browseOption>
          <commonOptions>
            <clusterDBBackedup>false</clusterDBBackedup>
            <onePassRestore>false</onePassRestore>
            <restoreToDisk>false</restoreToDisk>
          </commonOptions>
          <destination>
            <destClient>
              <clientName>$DestinationClientName</clientName>
            </destClient>
            <destinationInstance>
              <appName>SQL Server</appName>
              <clientName>$DestinationClientName</clientName>
              <instanceName>$DestinationInstanceName</instanceName>
            </destinationInstance>
          </destination>
          <fileOption/>
          <sharePointRstOption>
            <fetchSqlDatabases>false</fetchSqlDatabases>
          </sharePointRstOption>
          <sqlServerRstOption>
            <attachToSQLServer>false</attachToSQLServer>
            <checksum>false</checksum>
            <commonMountPath></commonMountPath>
            <continueaftererror>false</continueaftererror>
            <database>$SourceDatabaseName</database>
            <dbOnly>false</dbOnly>
            $devicesString
            <dropConnectionsToDatabase>true</dropConnectionsToDatabase>
            <ffgRestore>false</ffgRestore>
            <ignoreFullBackup>false</ignoreFullBackup>
            <keepDataCapture>false</keepDataCapture>
            <logShippingOnly>false</logShippingOnly>
            <overWrite>true</overWrite>
            <partialRestore>false</partialRestore>
            <pointOfTimeRst>false</pointOfTimeRst>
            <preserveReplicationSettings>false</preserveReplicationSettings>
            <restoreSource>$SourceDatabaseName</restoreSource>
            <restoreToDisk>false</restoreToDisk>
            <restoreToDiskPath></restoreToDiskPath>
            <sqlRecoverType>STATE_RECOVER</sqlRecoverType>
            <sqlRestoreType>DATABASE_RESTORE</sqlRestoreType>
            <sqlVerifyOnly>false</sqlVerifyOnly>
            <stopBeforeMarkRestore>false</stopBeforeMarkRestore>
            <stopMarkRestore>false</stopMarkRestore>
            <stopStartSSA>false</stopStartSSA>
            <timeZone>
              <TimeZoneName>(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna</TimeZoneName>
            </timeZone>
            <vSSBackup>false</vSSBackup>
          </sqlServerRstOption>
        </restoreOptions>
      </options>
      <subTask>
        <operationType>RESTORE</operationType>
        <subTaskType>RESTORE</subTaskType>
      </subTask>
    </subTasks>
    <task>
      <initiatedFrom>COMMANDLINE</initiatedFrom>
      <policyType>DATA_PROTECTION</policyType>
      <taskFlags>
        <disabled>false</disabled>
      </taskFlags>
      <taskType>IMMEDIATE</taskType>
    </task>
  </taskInfo>

</TMMsg_CreateTaskReq>
"@

        return $x
    }
}
