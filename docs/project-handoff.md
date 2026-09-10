# Project handoff

## Purpose and architecture

Three standalone PowerShell 5.1+ scripts for users checking duplicate `remote_path` or `record_id` values, or finding blank `remote_path` rows in a folder of CSV files. Uses built-in CSV parsing; duplicate scans use in-memory dictionaries and the blank scan retains only matching rows. No external dependencies or authentication are needed to run them.

## Current status and decisions

Implemented exact matching, optional case-insensitive matching, recursive discovery, configurable delimiter, blank-path skipping, and a CSV report with occurrence counts and source record locations. Source files are preserved and existing reports cannot be overwritten. Memory usage grows with input rows. Keep reports outside the input folder for repeated scans.

## Run and validate

```powershell
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\duplicates.csv'
.\Find-DuplicateRecordIds.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\duplicate-record-ids.csv'
.\Find-BlankRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\blank-remote-paths.csv'
```

The output directory must already exist. See README.md for options. Validation used temporary CSV fixtures and passed same-file and cross-file matching, quoted commas, blank values, case-sensitive and case-insensitive matching, no-match output, and overwrite protection.

## Next steps and limitations

No active implementation work or known blockers. Validate against representative user CSV files. For data too large to fit in memory, evaluate a disk-backed approach before extending the script. Empty and header-only files contribute no records; schema checking occurs on the first data record.

## Session log

- 2026-09-10: Added Find-BlankRemotePaths.ps1 with console progress, empty/whitespace matching, complete original rows, and source locations. Unions input columns and avoids metadata name collisions. Fixture validation passed empty/quoted-empty/whitespace matching, valid-path exclusion, recursion, field preservation, differing schemas, metadata collisions, leading zeros, custom delimiter, no-match output, overwrite protection, and missing-column errors. Next step: run against representative user CSVs.
- 2026-09-10: Added standalone Find-DuplicateRecordIds.ps1 with the same options and console progress as the remote-path checker. IDs stay strings (leading zeros preserved). Reports include all duplicate occurrences and source locations. Fixture validation passed duplicate counts, leading zeros, case sensitivity, blank IDs, quoted commas, recursive discovery, overwrite protection, custom delimiter, no matches, missing-column errors, and progress messages. Next step: validate against representative user CSVs.
- 2026-09-10: Added timestamped console progress for discovery, each file, periodic row counts (default 5 seconds, configurable with `-ProgressIntervalSeconds`), report generation, export, and elapsed completion time. Progress uses the information stream. Validated against real CSV fixtures and a slow input simulation to exercise periodic updates; duplicate results remain unchanged.
- 2026-09-10: Created the script and README, passed fixture validation, and prepared initial GitHub publication. This is a standalone utility with no scheduled jobs, workflows, services, or deployment requirements.
