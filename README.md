# Find duplicate remote paths

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
- CSV input is read as UTF-8. Blank paths are skipped. A CSV containing records but missing `remote_path` stops the scan.
- The report lists every matching occurrence, including the first, with its total occurrence count, full source filename, and data row number (1 is the first record after the header). Quoted multiline fields count as one record.
- No matches produces a header-only report. Empty and header-only input files contribute no records.
- Keep reports outside the input folder when running repeated scans, or move previous reports out before scanning again, so they are not counted as input.
- Memory usage grows with the number of nonblank rows; this script is intended for CSV collections that fit in memory.
