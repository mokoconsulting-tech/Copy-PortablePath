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

# Copy-PortablePath - README.md

**Copy-PortablePath** is a lightweight Windows enhancement that adds **“Copy Relative Path”** and **“Copy Absolute Path”** options to the right-click (context) menu in File Explorer.
It is designed for developers, IT staff, and anyone who needs quick, consistent path copying in a **portable-friendly format** (using `/` instead of `\\`).

---

## 📋 Features

* **Two copy modes**:

  * **Copy Relative Path** – Path relative to the script’s working directory.
  * **Copy Absolute Path** – Full absolute path to the file or folder.
* **Portable path format** (`/` separators) for cross-platform compatibility.
* **No dependencies** — works out of the box with PowerShell.
* **Install & uninstall scripts** for quick setup.

---

## 📂 Files in this repository

| File                    | Description                                    |
| ----------------------- | ---------------------------------------------- |
| `Copy-PortablePath.ps1` | Core PowerShell script for copying paths.      |
| `install.ps1`           | Registers the context menu entries in Windows. |
| `uninstall.ps1`         | Removes the context menu entries from Windows. |
| `README.md`             | This documentation.                            |
| `CHANGELOG.md`          | Version history and notable changes.           |

---

## 🚀 Installation

1. **Download** this repository or copy the required scripts to a local folder.
   Example:

   ```
   J:\\Shared drives\\Knowledgebase\\Scripts\\Copy-PortablePath\\
   ```

2. **Run the installer script** in PowerShell **as Administrator**:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\\install.ps1
   ```

3. **Restart File Explorer** (or log out and back in) to apply the new context menu entries.

---

## 🖱 Usage

1. **Right-click** a file or folder in File Explorer.
2. Select:

   * **Copy Relative Path** – Path relative to the script’s working directory.
   * **Copy Absolute Path** – Full path with `/` separators.
3. Paste into your application, code editor, or terminal.

---

## ⚙ Customization

* **Relative path base**
  Edit `$BasePath` in `Copy-PortablePath.ps1` to control how relative paths are calculated.

* **Separator style**
  Default: `/` for cross-platform use.
  Change:

  ```powershell
  $PortablePath = $Path -replace '\\\\','/'
  ```

  to:

  ```powershell
  $PortablePath = $Path
  ```

  to keep Windows `\\`.

* **Default mode bypass**
  Run the script directly with:

  ```powershell
  .\\Copy-PortablePath.ps1 -Mode Absolute
  ```

  or:

  ```powershell
  .\\Copy-PortablePath.ps1 -Mode Relative
  ```

---

## 🔄 Uninstallation

Run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\\uninstall.ps1
```

Or manually delete the registry keys created during installation.

---

## 🛠 Troubleshooting

| Issue              | Cause                                       | Fix                                 |
| ------------------ | ------------------------------------------- | ----------------------------------- |
| Menu items missing | Registry not applied or File Explorer cache | Restart File Explorer               |
| Clipboard empty    | `Set-Clipboard` blocked by policy           | Output to console and copy manually |
| Wrong path format  | Separator logic in script                   | Edit `$PortablePath` assignment     |

---

## 📜 License

Copyright (C) 2025 Moko Consulting
Licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later).
You may redistribute and/or modify this software under the terms of the GPL as published by the Free Software Foundation.

---

## 👨‍💻 Developer Notes

* Tested on Windows 11.
* Works with PowerShell 5.1 and 7+.
* Registry entries stored under `HKEY_CLASSES_ROOT`.
* Can be run from USB or network share for portability.

---

## 📦 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed version history.

---
