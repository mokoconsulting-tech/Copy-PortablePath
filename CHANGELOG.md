<<<<<<< Updated upstream
=======
<!--
 COPYRIGHT (C) 2025 Jonathan Miller || Moko Consulting <jmiller@mokoconsulting.tech>

 THIS FILE IS PART OF A MOKO CONSULTING PROJECT.

 SPDX-LICENSE-IDENTIFIER: GPL-3.0-OR-LATER

 THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR (AT YOUR OPTION) ANY LATER VERSION.

 THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU GENERAL PUBLIC LICENSE FOR MORE DETAILS.

 YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE ALONG WITH THIS PROGRAM. IF NOT, SEE <HTTPS://WWW.GNU.ORG/LICENSES/>.

 # FILE INFORMATION
	 INGROUP: 	Copy-PortablePath
	 FILE:			./CHANGELOG.md
	 VERSION:		1.0
	 BRIEF:			Version history and notable changes for the Copy-PortablePath project. NOTE:	All updates are documented in reverse chronological order.
	 PATH:			CHANGELOG.md
 -->
# Copy-PortablePath - CHANGELOG.md

All notable changes to this project will be documented here. This file follows a simple, human-friendly format inspired by “Keep a Changelog” and uses semantic versioning. Dates are in **YYYY-MM-DD** (America/Chicago).

## [1.0] — 2025-08-17 — Initial public release

### Added

* Self‑contained installer (no `\bin` layout) with manifest and SHA‑256 file hashes.
* Clean PATH add/remove with environment broadcast to running shells.
* Reinstall / uninstall prompts (or `-Silent`), plus post‑actions: Restart/Kill/Start Explorer, Restart System.
* Explorer right‑click verbs under HKCU for:

  * `AllFilesystemObjects\shell\Copy-PortablePath` (files & folders)
  * `Directory\shell\Copy-PortablePath` (explicit folders)
  * `Drive\shell\Copy-PortablePath` (drive root)
  * `Directory\Background\shell\Copy-PortablePath` (folder background — `%V`)
* Default icon resource: `%SystemRoot%\System32\imageres.dll,-5382` (as REG\_EXPAND\_SZ), with `-ContextIcon` override.
* `copy-portablepath` shim (`.cmd`) that picks `pwsh` or `powershell` automatically.
* Optional `cpp` profile alias function (CurrentUserAllHosts).
* Per‑day JSON history logs in `<InstallDir>\logs\history-YYYYMMDD.log` with `-HistoryShow` / `-HistoryClear`.
* Version stamping from `VERSION` file or `-Version` flag.
* Optional code‑signing hooks (thumbprint or PFX + timestamp).

### Changed

* Explorer integration: added explicit `Directory\shell` verb so folders consistently show **Copy Portable Path** (on Windows 11 it appears under *Show more options*).
* Default icon set to `%SystemRoot%\System32\imageres.dll,-5382` and stored as **REG\_EXPAND\_SZ** for reliable variable expansion.

### Fixed

* Robust registry writes (REG\_EXPAND\_SZ for Icon) and removal of `Extended` / `LegacyDisable` flags.
* Fallback to embedded tool if no external payload is provided.
* Guarded `EnvBroadcast` C# type to avoid redefinition errors on repeated runs.
* Legacy `Copy-PortablePath\bin` directory cleanup and PATH removal.

---
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
