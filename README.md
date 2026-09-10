# Find duplicate remote paths

## Find blank remote paths

```powershell
.\Find-BlankRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\blank-remote-paths.csv'
```

Finds rows where `remote_path` is empty (including CSV `""`) or contains only whitespace. Preserves all original columns and adds `SourceFile` and `DataRow` (the zero-based record index after the header: first record = 0, second = 1). This index resets for each file and counts parsed CSV records, not physical text lines or Excel row numbers. If these names already exist in input, metadata names gain leading underscores until unique. Different input schemas are combined without dropping columns.

Supports `-Recurse`, `-Delimiter`, and `-ProgressIntervalSeconds` (default 5), with automatic console progress. The default report is `blank-remote-paths.csv` in the input folder. Source files are unchanged and reports cannot be overwritten. Keep reports outside the input folder on repeated scans. Only matching rows are held in memory. No matches produces a header-only report; completely empty physical lines are ignored by the CSV parser. A missing `remote_path` column on a file with data records is an error, not a blank-path match.

## Find duplicate record IDs

To check `record_id` instead, use the standalone companion script:

```powershell
.\Find-DuplicateRecordIds.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\duplicate-record-ids.csv'
```

It finds matching IDs within and across CSV files and reports every occurrence with `record_id`, `OccurrenceCount`, `SourceFile`, and `DataRow`. IDs are compared as text, so `001` and `1` remain different. Blank IDs are skipped; matching is case-sensitive by default. All options below, including console progress, also apply to this script. Without `-OutputPath`, it writes `duplicate-record-ids.csv` inside the input folder. Keep reports from either script outside the input folder before subsequent scans.

## Find duplicate remote paths

Run in PowerShell 5.1 or later:

```powershell
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles'
```

Checks `remote_path` values within and across all CSV files directly in the folder. Source CSVs are never modified. The default output is `duplicate-remote-paths.csv` in that folder; an existing report is never overwritten.

```powershell
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -Recurse -IgnoreCase -OutputPath 'C:\Reports\duplicates.csv'
```

- `-Recurse`: include subfolders.
- `-IgnoreCase`: treat paths differing only in case as equal. Default matching is exact and case-sensitive, with whitespace preserved.
- `-Delimiter ';'`: read semicolon-separated CSVs.
- Console progress is enabled automatically: timestamped discovery, file start/end, report-building, export, and completion messages. During row processing, updates appear every 5 seconds with current-file rows, total rows, unique paths, skipped blanks, and elapsed time. No total-row percentage is estimated because CSVs are read once.
- `-ProgressIntervalSeconds 10`: change the row-processing update interval (1–3600 seconds). Updates occur as records are processed; a blocked read does not produce a heartbeat. Progress uses the host/information stream, keeping it out of the CSV report.
- CSV input is read as UTF-8. Blank paths are skipped. A CSV containing records but missing `remote_path` stops the scan.
- The report lists every matching occurrence, including the first, with its total occurrence count, full source filename, and data row number (1 is the first record after the header). Quoted multiline fields count as one record.
- No matches produces a header-only report. Empty and header-only input files contribute no records.
- Keep reports outside the input folder when running repeated scans, or move previous reports out before scanning again, so they are not counted as input.
- Memory usage grows with the number of nonblank rows; this script is intended for CSV collections that fit in memory.
