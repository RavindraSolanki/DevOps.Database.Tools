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
