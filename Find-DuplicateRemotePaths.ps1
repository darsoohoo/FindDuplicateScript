#Requires -Version 5.1
<#
.SYNOPSIS
Finds duplicate remote_path values within and across CSV files.
.EXAMPLE
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles'
.EXAMPLE
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -Recurse -IgnoreCase -OutputPath 'C:\Reports\duplicates.csv'
.NOTES
Matching is exact and case-sensitive by default; whitespace is preserved.
Blank remote_path values are skipped. DataRow is the CSV record number,
starting at 1 after the header (not the physical line number).
The report includes every occurrence of each duplicated value.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FolderPath,

    [string]$OutputPath,
    [switch]$Recurse,
    [switch]$IgnoreCase,
    [char]$Delimiter = ','
)

$ErrorActionPreference = 'Stop'
$folder = Get-Item -LiteralPath $FolderPath
if (-not $folder.PSIsContainer) {
    throw "FolderPath must point to a folder: $FolderPath"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $folder.FullName 'duplicate-remote-paths.csv'
}
$reportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
if (Test-Path -LiteralPath $reportPath) {
    throw "Report already exists: $reportPath. Choose a new OutputPath or move the existing report before running again."
}
$reportDirectory = Split-Path -Parent $reportPath
if (-not (Test-Path -LiteralPath $reportDirectory -PathType Container)) {
    throw "Report folder does not exist: $reportDirectory"
}

$files = @(Get-ChildItem -LiteralPath $folder.FullName -Filter '*.csv' -File -Recurse:$Recurse |
    Where-Object { $_.FullName -ne $reportPath } | Sort-Object FullName)
if ($files.Count -eq 0) {
    throw "No CSV files found in: $($folder.FullName)"
}

$comparer = [System.StringComparer]::Ordinal
if ($IgnoreCase) { $comparer = [System.StringComparer]::OrdinalIgnoreCase }
$seen = [System.Collections.Generic.Dictionary[string, object]]::new($comparer)
$totalRows = 0L
$blankRows = 0L

foreach ($file in $files) {
    Write-Verbose "Reading $($file.FullName)"
    $dataRow = 0L
    Import-Csv -LiteralPath $file.FullName -Delimiter $Delimiter -Encoding UTF8 | ForEach-Object {
        $dataRow++
        $totalRows++
        if ($dataRow -eq 1 -and $_.PSObject.Properties.Name -notcontains 'remote_path') {
            throw "CSV is missing the remote_path column: $($file.FullName)"
        }

        $remotePath = [string]$_.remote_path
        if ([string]::IsNullOrWhiteSpace($remotePath)) {
            $blankRows++
        }
        else {
            $occurrence = [pscustomobject]@{
                remote_path = $remotePath
                SourceFile = $file.FullName
                DataRow = $dataRow
            }
            if (-not $seen.ContainsKey($remotePath)) {
                $seen.Add($remotePath, [System.Collections.Generic.List[object]]::new())
            }
            $seen[$remotePath].Add($occurrence)
        }
    }
}

$duplicateGroups = 0L
$duplicateRows = 0L
$report = @(
    foreach ($entry in $seen.GetEnumerator()) {
        if ($entry.Value.Count -gt 1) {
            $duplicateGroups++
            $duplicateRows += $entry.Value.Count
            foreach ($occurrence in $entry.Value) {
                [pscustomobject]@{
                    remote_path = $occurrence.remote_path
                    OccurrenceCount = $entry.Value.Count
                    SourceFile = $occurrence.SourceFile
                    DataRow = $occurrence.DataRow
                }
            }
        }
    }
)

if ($report.Count -gt 0) {
    $report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8 -NoClobber
}
else {
    # Write a header-only report when there are no duplicates.
    '"remote_path","OccurrenceCount","SourceFile","DataRow"' |
        Out-File -LiteralPath $reportPath -Encoding UTF8 -NoClobber
}

Write-Host "Scanned $($files.Count) CSV files and $totalRows data rows; skipped $blankRows blank paths."
Write-Host "Found $duplicateGroups duplicated paths across $duplicateRows rows."
Write-Host "Report: $reportPath"
