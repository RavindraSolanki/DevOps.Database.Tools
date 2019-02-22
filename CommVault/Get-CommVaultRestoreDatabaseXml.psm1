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
