# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-08-11

### Security
- **CRITICAL FIX**: Fixed critical vulnerability in restore module that could delete system directories during full synchronization mode
- Added protection filters for excluded paths during `--delete` operations to prevent accidental system corruption

### Changed
- Enhanced `execute_rsync()` function to accept protection paths parameter for safer full synchronization
- Improved variable scoping by removing global variables in favor of local nameref parameters
- Updated rsync command structure to include `--filter='protect'` options for excluded paths

### Technical Details
- Modified `src/modules/restore.sh:execute_rsync()` function signature to include `protect_paths_ref` parameter
- Replaced unsafe global variable `CURRENT_EXCLUDE_PATHS` with local variable passing
- Added dynamic protection filter generation based on `META_EXCLUDE` or `log_exclude_paths` arrays
- Fixed potential system destruction scenario where `/proc`, `/sys`, `/dev` could be deleted during restoration

### Testing
- Added comprehensive test coverage for full synchronization mode
- Verified protection of critical system directories (`/proc`, `/sys`, `/dev`)
- Validated proper handling of both log.json and meta.sh exclude path sources

## [1.1.0] - 2025-02-09

### Added
- Added `log` command to view backup notes and logs
- Enhanced backup logging with detailed JSON structure
- Implemented backup metadata storage in `log.json`

### Changed
- Improved list command with pagination and better formatting
- Enhanced backup process with exclude path logging
- Updated documentation structure

### Fixed
- Fixed backup size calculation accuracy
- Improved error handling in backup operations

## [Previous Versions]
- See git history for details on versions prior to 1.1.0