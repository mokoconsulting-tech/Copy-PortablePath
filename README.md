<!--
Copyright (C) 2025 Moko Consulting <hello@mokoconsulting.tech>

This file is part of the Copy-PortablePath project.

Copy-PortablePath is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Copy-PortablePath is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Copy-PortablePath. If not, see <https://www.gnu.org/licenses/>.
-->

Copy-PortablePath - README.md

Copy-PortablePath is a lightweight Windows enhancement that adds “Copy Relative Path” and “Copy Absolute Path” options to the right-click (context) menu in File Explorer. It is designed for developers, IT staff, and anyone who needs quick, consistent path copying in a portable-friendly format (using / instead of \).

📋 Features

Two copy modes:

Copy Relative Path – Path relative to the script’s working directory.

Copy Absolute Path – Full absolute path to the file or folder.

Portable path format (/ separators) for cross-platform compatibility.

No dependencies — works out of the box with PowerShell.

Error handling — detects and reports missing files, registry issues, and permission errors.

Installation check — verifies if context menu entries are already installed before making changes.

Installer can be run from right-click — Simply right-click install.ps1 and select Run with PowerShell to install without opening a terminal.

📦 Prerequisites

Windows 11 (tested)

PowerShell 5.1 or PowerShell 7+ installed (preinstalled on Windows, but can be updated from Microsoft's official PowerShell releases if needed).

Administrator privileges to install and modify registry entries.

📂 Files in this repository

File

Description

Copy-PortablePath.ps1

Core PowerShell script for copying paths.

install.ps1

Registers the context menu entries in Windows with installation checks and error handling.

uninstall.ps1

Removes the context menu entries from Windows.

README.md

This documentation.

CHANGELOG.md

Version history and notable changes.

CONTRIBUTING.md

Contribution guidelines for developers.

CODE_OF_CONDUCT.md

Code of conduct for contributors and community members.

🚀 Installation

Method 1 – Run from PowerShell

Download this repository and place the files in a permanent location, for example:

C:/Tools/Copy-PortablePath/

Open PowerShell as Administrator.

Allow script execution for the current session:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Run the installer script:

C:/Tools/Copy-PortablePath/install.ps1

The installer will:

Check if context menu entries are already installed.

Display a message and exit if already installed.

Apply registry changes if not installed.

Show error details if any issues occur.

Restart File Explorer using one of the following methods:

Option 1 – Task Manager: Press Ctrl + Shift + Esc, find Windows Explorer, select it, and click Restart.

Option 2 – Command: Open PowerShell or Command Prompt and run:

taskkill /f /im explorer.exe
start explorer.exe

Option 3 – Log out and back in.

Option 4 – Restart the computer.

Method 2 – Run from Right-Click

Locate install.ps1 in File Explorer.

Right-click the file and select Run with PowerShell.

Accept any prompts and wait for confirmation.

Restart File Explorer using any of the methods above.

Option 1 – Task Manager: Press Ctrl + Shift + Esc, find Windows Explorer, select it, and click Restart.

Option 2 – Command: Open PowerShell or Command Prompt and run:

taskkill /f /im explorer.exe
start explorer.exe

Option 3 – Log out and back in.

Option 4 – Restart the computer.

🖱 Usage

Right-click a file or folder in File Explorer.

Select:

Copy Relative Path – Path relative to the script’s working directory.

Copy Absolute Path – Full path with / separators.

Paste into your application, code editor, or terminal.

⚙ Customization

Relative path base – Edit $BasePath in Copy-PortablePath.ps1 to control how relative paths are calculated.

Separator style – Default is / for cross-platform use. Change:

$PortablePath = $Path -replace '\\','/'

to:

$PortablePath = $Path

to keep Windows \\.

Default mode bypass – Run the script directly:

C:/Tools/Copy-PortablePath/Copy-PortablePath.ps1 -Mode Absolute
C:/Tools/Copy-PortablePath/Copy-PortablePath.ps1 -Mode Relative

🔄 Uninstallation

Run:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
C:/Tools/Copy-PortablePath/uninstall.ps1

Or right-click uninstall.ps1 and select Run with PowerShell.

The uninstall script includes checks to confirm:

If the registry entries exist before attempting removal.

If removal was successful, with error reporting if not.

Restart File Explorer using any of the methods listed above.

🛠 Troubleshooting

Issue

Cause

Fix

Menu items missing

Registry not applied or File Explorer cache

Restart File Explorer

Clipboard empty

Set-Clipboard blocked by policy

Output to console and copy manually

Wrong path format

Separator logic in script

Edit $PortablePath assignment

Install script fails

Missing permissions or registry access denied

Run PowerShell as Administrator

📜 License

Copyright (C) 2025 Moko ConsultingLicensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later).You may redistribute and/or modify this software under the terms of the GPL as published by the Free Software Foundation.

👨‍💻 Developer Notes

Tested on Windows 11.

Works with PowerShell 5.1 and 7+.

Registry entries stored under HKEY_CLASSES_ROOT.

Can be run from USB or network share for portability.

install.ps1 and uninstall.ps1 both include error handling and installation state checks.

📦 Changelog

See CHANGELOG.md for a detailed version history.

🤝 Contributing

Please read CONTRIBUTING.md for details on how to contribute to this project.

📏 Code of Conduct

This project follows a strict CODE_OF_CONDUCT.md to ensure a welcoming and respectful environment for all contributors and users.

