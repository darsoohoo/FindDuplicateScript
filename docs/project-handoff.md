# Project handoff

## Purpose and architecture

A standalone PowerShell 5.1+ script for users checking duplicate `remote_path` values within and across a folder of CSV files. Uses built-in CSV parsing and an in-memory dictionary; no external dependencies or authentication are needed to run it.

## Current status and decisions

Implemented exact matching, optional case-insensitive matching, recursive discovery, configurable delimiter, blank-path skipping, and a CSV report with occurrence counts and source record locations. Source files are preserved and existing reports cannot be overwritten. Memory usage grows with input rows. Keep reports outside the input folder for repeated scans.

## Run and validate

```powershell
.\Find-DuplicateRemotePaths.ps1 -FolderPath 'C:\Data\CsvFiles' -OutputPath 'C:\Reports\duplicates.csv'
```

The output directory must already exist. See README.md for options. Validation used temporary CSV fixtures and passed same-file and cross-file matching, quoted commas, blank values, case-sensitive and case-insensitive matching, no-match output, and overwrite protection.

## Next steps and limitations

No active implementation work or known blockers. Validate against representative user CSV files. For data too large to fit in memory, evaluate a disk-backed approach before extending the script. Empty and header-only files contribute no records; schema checking occurs on the first data record.

## Session log

- 2026-09-10: Created the script and README, passed fixture validation, and prepared initial GitHub publication. This is a standalone utility with no scheduled jobs, workflows, services, or deployment requirements.
