<!--
 Copyright (C) 2025 Moko Consulting <hello@mokoconsulting.tech>

 This file is part of the Copy-PortablePath project.

 SPDX-LICENSE-IDENTIFIER: GPL-3.0-OR-LATER

 THIS PROGRAM IS FREE SOFTWARE: YOU CAN REDISTRIBUTE IT AND/OR MODIFY IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY THE FREE SOFTWARE FOUNDATION, EITHER VERSION 3 OF THE LICENSE, OR (AT YOUR OPTION) ANY LATER VERSION.

 THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU GENERAL PUBLIC LICENSE FOR MORE DETAILS.

 YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE ALONG WITH THIS PROGRAM. IF NOT, SEE <HTTPS://WWW.GNU.ORG/LICENSES/>.

# FILE INFORMATION
	INGROUP: 	Copy-PortablePath
	FILE: 		README.md
	VERSION: 	1.0
	Brief: 		README for Copy-PortablePath — a tiny Windows helper that resolves any file or folder to a forward-slash “portable” path, with optional clipboard copy, Explorer right-click integration, a self-contained installer, clean PATH updates, a shim launcher, and per-day history logs.
	PATH: 		./README.md
-->

# Copy‑PortablePath - README.md

*Version 1.0 · GPL-3.0-or-later · Maintainer: Jonathan Miller (Moko Consulting) · Repo: [mokoconsulting-tech/Copy-PortablePath](https://github.com/mokoconsulting-tech/Copy-PortablePath)*

A tiny Windows helper that resolves any file or folder to a **portable path** (forward slashes) and optionally copies it to the clipboard. Ships with a **self‑contained installer**, an **Explorer right‑click menu** entry, clean **PATH** management, a **shim** (`copy-portablepath`), and per‑day **history logs**.

---

## Table of contents

* [Features](#features)
* [Requirements](#requirements)
* [Quick start](#quick-start)
* [Using the tool](#using-the-tool)
* [Command reference](#command-reference)
* [Explorer right‑click menu](#explorer-right-click-menu)
* [Installer options (high‑level)](#installer-options-high-level)
* [Installer reference](#installer-reference)
* [PATH behavior](#path-behavior)
* [Logging](#logging)
* [Registry keys](#registry-keys)
* [Uninstall / Reinstall](#uninstall--reinstall)
* [Manifest](#manifest)
* [Troubleshooting](#troubleshooting)
* [Contributing](#contributing)
* [License](#license)
* [Changelog](#changelog)

## Features

* **Portable path output**: `C:\Users\me\Docs` → `C:/Users/me/Docs`.
* **Clipboard switch**: add `-Clip` to copy immediately.
* **Explorer integration** (HKCU): shows **Copy Portable Path** on files, folders, drives, and folder background (Win11 → *Show more options*).
* **Self‑contained installer**: works even without a separate payload—embeds a minimal tool if needed.
* **Clean PATH management**: adds/removes the install directory and broadcasts changes to the shell.
* **Reinstall / uninstall** flow with prompts (or `-Silent`).
* **Manifest + version stamping**: JSON manifest with file hashes; shim banner stamped from `VERSION` or `-Version`.
* **History logging**: per‑day JSON lines under `<InstallDir>\logs\history-YYYYMMDD.log`.
* **Optional profile alias**: `cpp` function for quick use.
* **Optional code signing** hooks.

---

## Requirements

* Windows 10/11
* PowerShell 5.1 **or** PowerShell 7+

---

## Quick start

```powershell
# From the repo root (creates ./logs transcript)
.\install.ps1

# One‑liner: silent install, add Explorer verb, restart Explorer
.\install.ps1 -Silent -RegisterContextMenu -PostAction RestartExplorer
```

* Default install **scope** is **User** (`%LOCALAPPDATA%\Copy-PortablePath`).
* The installer writes an install **manifest** to `<InstallDir>\install-manifest.json` and a `VERSION` file.
* A shim is created at `<InstallDir>\copy-portablepath.cmd`.

---

## Using the tool

```powershell
# Print the portable path for the current directory
copy-portablepath .

# Copy a specific folder path to clipboard
copy-portablepath "J:\\Shared drives\\Development\\Projects\\Copy-PortablePath" -Clip

# Show today’s history (last 20 entries)
copy-portablepath -HistoryShow -Tail 20

# Clear today’s history
copy-portablepath -HistoryClear
```

**Outputs**: a single line with forward slashes. When `-Clip` is used, also writes to the clipboard.

**History**: Each run appends a JSON record (timestamp, user, host, pwsh version, input, resolved path, clip=true/false) to `<InstallDir>\logs\history-YYYYMMDD.log`.

---

## Command reference

### `Copy-PortablePath.ps1`

**Synopsis**: Resolve a file or folder to a portable path (forward slashes) and optionally copy to clipboard.

**Usage**

```powershell
Copy-PortablePath.ps1 [-Path <string>] [-Clip] [-HistoryShow] [-HistoryClear] [-Tail <int>] [-Help]
# or via shim
copy-portablepath [<path>] [-Clip] [-HistoryShow] [-HistoryClear] [-Tail <int>]
```

**Parameters**

* `-Path <string>` — File or folder to resolve. Defaults to the current directory (`.`).
* `-Clip` — Copies the resolved path to the clipboard in addition to printing it.
* `-HistoryShow` — Prints today’s history log to the console. Use `-Tail` to limit lines.
* `-HistoryClear` — Deletes today’s history log file.
* `-Tail <int>` — Number of lines to show from the end of today’s history (default 100).
* `-Help` / `-?` / `-h` — Show brief usage.

**Output**

* One line, forward‑slash path (e.g., `C:/Users/alex/Docs`). Non‑zero exit on error.

**Examples**

```powershell
copy-portablepath .
copy-portablepath 'C:\Temp' -Clip
copy-portablepath -HistoryShow -Tail 20
```

---

## Explorer right‑click menu

The installer can register these verbs under **HKCU** (no admin):

* `AllFilesystemObjects\shell\Copy-PortablePath` (files & folders)
* `Directory\shell\Copy-PortablePath` (folders explicitly)
* `Drive\shell\Copy-PortablePath` (drive root)
* `Directory\Background\shell\Copy-PortablePath` (folder background — uses `%V`)

**Default icon**: `%SystemRoot%\System32\imageres.dll,-5382` (written as `REG_EXPAND_SZ`).

```powershell
# Add the context menu and restart Explorer
.\install.ps1 -Silent -RegisterContextMenu -PostAction RestartExplorer

# Choose another built‑in icon
.\install.ps1 -Silent -RegisterContextMenu -ContextIcon '%SystemRoot%\System32\shell32.dll,-167'

# Remove the context menu
.\install.ps1 -Silent -UnregisterContextMenu -PostAction RestartExplorer
```

> **Windows 11**: custom verbs appear under **Show more options** (Shift+F10) unless implemented with a modern IExplorerCommand handler.

---

## Installer options (high‑level)

```powershell
# Scope
-Scope User|System            # System requires elevation; falls back to User if not elevated

# Behavior
-Reinstall                    # Clean uninstall then install
-Uninstall                    # Remove files, PATH entry, manifest; unregister verbs
-Silent                       # No prompts; defaults to User + Reinstall
-NoPath                       # Don’t modify PATH
-Force                        # Overwrite files and re‑add PATH even if present

# Explorer verbs
-RegisterContextMenu          # Add right‑click entries (HKCU)
-UnregisterContextMenu        # Remove right‑click entries
-ContextIcon '<resource>'     # e.g., '%SystemRoot%\System32\imageres.dll,-5382'

# Post actions
-PostAction None|RestartExplorer|KillExplorer|StartExplorer|RestartSystem

# Payload & version
-Source <path|url>            # Directory or .ps1 payload; otherwise embed stub
-InstallDir <path>            # Default: %LOCALAPPDATA%\Copy-PortablePath (User)
-Version <x.y.z>              # Or from ./VERSION; default 1.0

# Extras
-AddProfileAlias              # Adds 'cpp' function to CurrentUserAllHosts profile
-Sign [-CertThumbprint ...]   # Sign installed .ps1 files (or -CertPath .pfx)
-TimestampServer <url>        # Default: http://timestamp.digicert.com
```

---

## Installer reference

### Behavior & flow

* **Interactive**: prompts for *scope* (User/System), existing‑install action (Reinstall/Uninstall/Leave), and post‑action unless `-Silent`.
* **Silent**: implies `-Scope User` and `-Reinstall` unless overridden.
* **Self‑contained**: if no payload is provided and no sibling `Copy-PortablePath.ps1` is found, a minimal tool is embedded and installed.

### Parameters (detail)

* `-Scope User|System` — Where to install and which PATH is updated. System requires elevation; falls back to User if not elevated.
* `-InstallDir <path>` — Destination directory (no `\bin` subfolder).
* `-Source <path|url>` — Directory (all `*.ps1`) or single `.ps1`; HTTPS URLs are downloaded to a temp file.
* `-Reinstall` — Remove existing files/manifest/PATH entry first, then install.
* `-Uninstall` — Remove files, PATH entry, manifest; unregister context‑menu.
* `-NoPath` — Skip PATH modifications.
* `-Force` — Overwrite files and re‑add PATH entries even if present.
* `-RegisterContextMenu` / `-UnregisterContextMenu` — Add/remove Explorer verbs (HKCU).
* `-ContextIcon '<resource>'` — DLL resource path, e.g. `%SystemRoot%\System32\imageres.dll,-5382`.
* `-PostAction None|RestartExplorer|KillExplorer|StartExplorer|RestartSystem` — What to do after install/uninstall.
* `-AddProfileAlias` — Appends a `cpp` function to the CurrentUserAllHosts profile to call the shim.
* `-Version <x.y.z>` — Stamped into `VERSION`, manifest, and the shim banner (default `1.0`).
* `-Sign` `[-CertThumbprint <hex>]` or `-Sign -CertPath <.pfx> [-CertPassword <secure>]` — Sign all installed `.ps1` files. Timestamp via `-TimestampServer` (defaults to DigiCert).
* `-ManifestPath <path>` — Custom path for the install manifest JSON.
* `-RepoUrl <url>` — Persisted to manifest.

### What gets installed

* `Copy-PortablePath.ps1` — the tool.
* `copy-portablepath.cmd` — shim (prefers `pwsh`, falls back to `powershell`).
* `VERSION` — plain‑text version.
* `install-manifest.json` — manifest with file hashes.
* *(optional)* `logs\history-YYYYMMDD.log` — created on first tool run.

### Exit codes

* `0` success; non‑zero on errors (e.g., payload not found, access denied during install, bad path input when running the tool).

## Uninstall / Reinstall

```powershell
# Full uninstall (User scope by default)
.\install.ps1 -Uninstall -Silent -UnregisterContextMenu -PostAction RestartExplorer

# Clean reinstall (idempotent)
.\install.ps1 -Silent -Reinstall -RegisterContextMenu -PostAction RestartExplorer
```

The installer also removes legacy `Copy-PortablePath\bin` directories and their PATH entries.

---

## PATH behavior

* Modifies **User** or **Machine** `Path` per `-Scope`.
* Broadcasts a `WM_SETTINGCHANGE` for "Environment" so new shells pick up the update immediately.
* The current process PATH is refreshed to `Machine;User` to avoid clobbering system entries.

---

## Logging

* **Installer transcript**: `./logs/copy-portablepath-(install|uninstall)-<Scope>-YYYYMMDD-HHMMSS.log` (created next to `install.ps1`).
* **Tool history**: `<InstallDir>\logs\history-YYYYMMDD.log` (JSON lines). Use `-HistoryShow` / `-HistoryClear`.

---

## Registry keys

Created under **HKCU** by `-RegisterContextMenu`:

* `Software\Classes\AllFilesystemObjects\shell\Copy-PortablePath` → `command` = `"<InstallDir>\copy-portablepath.cmd" "%1" -Clip`
* `Software\Classes\Directory\shell\Copy-PortablePath` → `command` = `"<InstallDir>\copy-portablepath.cmd" "%1" -Clip`
* `Software\Classes\Drive\shell\Copy-PortablePath` → `command` = `"<InstallDir>\copy-portablepath.cmd" "%1" -Clip`
* `Software\Classes\Directory\Background\shell\Copy-PortablePath` → `command` = `"<InstallDir>\copy-portablepath.cmd" "%V" -Clip`

Each verb also sets `MUIVerb = "Copy Portable Path"` and `Icon = %SystemRoot%\System32\imageres.dll,-5382` as **REG\_EXPAND\_SZ**.

---

## Manifest

A JSON manifest is written after every successful install:

```json
{
	"packageName": "Copy-PortablePath",
	"version": "1.0",
	"installDate": "2025-08-17T16:41:29.9486603-05:00",
	"scope": "User",
	"installDir": "C:\\Users\\<you>\\AppData\\Local\\Copy-PortablePath",
	"repoUrl": "https://github.com/mokoconsulting-tech/Copy-PortablePath",
	"files": [
		{ "path": "C:\\Users\\<you>\\AppData\\Local\\Copy-PortablePath\\Copy-PortablePath.ps1",
			"sha256": "<hash>" },
		{ "path": "C:\\Users\\<you>\\AppData\\Local\\Copy-PortablePath\\copy-portablepath.cmd",
			"sha256": "<hash>" }
	]
}
```

---

## Troubleshooting

* **Icon not visible on Windows 11**: open the classic menu via **Show more options**.
* **Verb missing on folders**: re‑register (we create both `AllFilesystemObjects` and `Directory` verbs):

	```powershell
	.\install.ps1 -Silent -RegisterContextMenu -PostAction RestartExplorer
	```
* **PATH didn’t update in current window**: start a new PowerShell session, or run the installer again (it broadcasts the change).
* **Execution Policy**: the shim launches with `-ExecutionPolicy Bypass`, so no system change is required.
* **Downloaded scripts blocked**: run `Unblock-File .\install.ps1` if SmartScreen added MOTW.

---

## Contributing

PRs welcome. Keep the installer idempotent, small, and resilient:

* Avoid silent failures—log to `./logs` and write clear `Write-Warning` messages.
* Prefer HKCU for shell integration.
* Use `REG_EXPAND_SZ` for icon resources and quote `%1` / `%V` properly.
* Don’t re‑add `Copy-PortablePath\\bin`; we’re bin‑less by design.

---

## License

GPL‑3.0‑or‑later. See `LICENSE`.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.
