#Requires -Version 5.1
<#
.SYNOPSIS
Finds CSV rows whose remote_path is empty or contains only whitespace.
.EXAMPLE
.\Find-BlankRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles'
.NOTES
Reports all original columns plus SourceFile and DataRow (0-based CSV record
index after the header). Metadata names gain underscores if input names clash.
CSV "" is an empty value. Completely empty physical lines are ignored by Import-Csv.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FolderPath,
    [string]$OutputPath,
    [switch]$Recurse,
    [char]$Delimiter = ',',
    [ValidateRange(1, 3600)]
    [int]$ProgressIntervalSeconds = 5
)

$ErrorActionPreference = 'Stop'
$folder = Get-Item -LiteralPath $FolderPath
if (-not $folder.PSIsContainer) { throw "FolderPath must point to a folder: $FolderPath" }
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $folder.FullName 'blank-remote-paths.csv'
}
$reportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if (Test-Path -LiteralPath $reportPath) {
    throw "Report already exists: $reportPath. Choose a new OutputPath or move the existing report before running again."
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $reportPath) -PathType Container)) {
    throw "Report folder does not exist: $(Split-Path -Parent $reportPath)"
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Discovering CSV files in $($folder.FullName)..."
$files = @(Get-ChildItem -LiteralPath $folder.FullName -Filter '*.csv' -File -Recurse:$Recurse |
    Where-Object { $_.FullName -ne $reportPath } | Sort-Object FullName)
if ($files.Count -eq 0) { throw "No CSV files found in: $($folder.FullName)" }

$matches = [System.Collections.Generic.List[object]]::new()
$columns = [System.Collections.Generic.List[string]]::new()
$columnSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$totalRows = 0L
$fileNumber = 0
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
$lastProgressSeconds = 0.0
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Found $($files.Count) CSV files. Starting scan."

foreach ($file in $files) {
    $fileNumber++
    $dataRow = 0L
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Reading file $fileNumber/$($files.Count): $($file.FullName)"
    Import-Csv -LiteralPath $file.FullName -Delimiter $Delimiter -Encoding UTF8 | ForEach-Object {
        $totalRows++
        if ($dataRow -eq 0) {
            if ($_.PSObject.Properties.Name -notcontains 'remote_path') {
                throw "CSV is missing the remote_path column: $($file.FullName)"
            }
            foreach ($name in $_.PSObject.Properties.Name) {
                if ($columnSet.Add($name)) { $columns.Add($name) }
            }
        }
        if ([string]::IsNullOrWhiteSpace([string]$_.remote_path)) {
            $matches.Add([pscustomobject]@{ Row = $_; SourceFile = $file.FullName; DataRow = $dataRow })
        }
        $dataRow++
        if (($elapsed.Elapsed.TotalSeconds - $lastProgressSeconds) -ge $ProgressIntervalSeconds) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] File $fileNumber/$($files.Count): $dataRow rows read; total $totalRows rows; $($matches.Count) blank paths found; elapsed $($elapsed.Elapsed.ToString('hh\:mm\:ss'))."
            $lastProgressSeconds = $elapsed.Elapsed.TotalSeconds
        }
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Finished file $fileNumber/$($files.Count): $dataRow rows; $($matches.Count) blank paths found so far."
}

# Use the union of input columns so differing CSV schemas do not lose fields.
if ($columns.Count -eq 0) { $columns.Add('remote_path'); [void]$columnSet.Add('remote_path') }
$sourceColumn = 'SourceFile'
while ($columnSet.Contains($sourceColumn)) { $sourceColumn = '_' + $sourceColumn }
$rowColumn = 'DataRow'
while ($columnSet.Contains($rowColumn)) { $rowColumn = '_' + $rowColumn }

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Writing $($matches.Count) matching rows to $reportPath..."
if ($matches.Count -gt 0) {
    & {
        foreach ($match in $matches) {
            $outputRow = [ordered]@{}
            foreach ($name in $columns) { $outputRow[$name] = $match.Row.PSObject.Properties[$name].Value }
            $outputRow[$sourceColumn] = $match.SourceFile
            $outputRow[$rowColumn] = $match.DataRow
            [pscustomobject]$outputRow
        }
    } | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8 -NoClobber
}
else {
    $emptyRow = [ordered]@{}
    foreach ($name in $columns) { $emptyRow[$name] = '' }
    $emptyRow[$sourceColumn] = ''
    $emptyRow[$rowColumn] = ''
    ([pscustomobject]$emptyRow | ConvertTo-Csv -NoTypeInformation | Select-Object -First 1) |
        Out-File -LiteralPath $reportPath -Encoding UTF8 -NoClobber
}
$elapsed.Stop()
Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Completed in $($elapsed.Elapsed.ToString('hh\:mm\:ss'))."
Write-Host "Scanned $($files.Count) CSV files and $totalRows data rows; found $($matches.Count) rows with blank remote_path values."
Write-Host "Report: $reportPath"
