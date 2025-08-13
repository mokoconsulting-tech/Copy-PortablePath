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

This project’s documentation and scripts were created with assistance from OpenAI’s ChatGPT.
-->

# Copy-PortablePath - README.md

**Copy-PortablePath** is a lightweight Windows utility that adds **“Copy Relative Path”** and **“Copy Absolute Path”** options to the right-click context menu in File Explorer. It is designed for developers, IT professionals, and anyone who needs quick, consistent path copying in a **portable-friendly format** (using `/` instead of `\`).

---

## 📋 Features

* **Two copy modes**:

  * **Copy Relative Path** – Path relative to a defined base directory.
  * **Copy Absolute Path** – Full file or folder path.
* **Portable path format** (`/` separators) for cross-platform compatibility.
* **No external dependencies** — works natively with PowerShell.
* **Error handling** — detects missing files, registry errors, and permission issues.
* **Installation check** — ensures context menu entries aren’t duplicated.
* **One-click installer** — can be run directly from the right-click menu.

---

## 📦 Prerequisites

* **Windows 11** (tested)
* **PowerShell 5.1** or **PowerShell 7+**
* Administrator rights for installation/uninstallation
* Script execution enabled (`Set-ExecutionPolicy` may need adjustment)

---

## 📂 Repository Structure

```
Copy-PortablePath/
├── Copy-PortablePath.ps1     # Main script
├── install.ps1               # Installer
├── uninstall.ps1             # Uninstaller
├── README.md                 # This file
├── CHANGELOG.md              # Version history
├── CONTRIBUTING.md           # Contribution guidelines
├── CODE_OF_CONDUCT.md        # Community rules
└── tests/                    # Test scripts and validation files
	 ├── Paths.Tests.ps1        # Pester tests for path manipulation functions
	 ├── Registry.Tests.ps1     # Pester/mock tests for registry-related functions
	 ├── Install.Tests.ps1      # Tests installer functionality
	 ├── Uninstall.Tests.ps1    # Tests uninstaller functionality
	 ├── PathFormat.Tests.ps1   # Validates portable path format output
	 └── README.md              # Documentation for running tests
```

---

## 🚀 Installation

### Method 1 – PowerShell

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
C:/path/to/install.ps1
```

### Method 2 – Right-Click

1. Locate `install.ps1` in File Explorer.
2. Right-click → **Run with PowerShell**.

---

## 🔄 Restarting File Explorer or the Computer

After installation or uninstallation, changes will take effect after restarting File Explorer or the system. You can choose any of the following methods:

### Restart File Explorer Only (No Logout or Reboot)

* **Task Manager:** Press `Ctrl + Shift + Esc`, locate **Windows Explorer**, right-click it, and select **Restart**.
* **Command Line:**

  ```powershell
  taskkill /f /im explorer.exe
  start explorer.exe
  ```

### Restart by Logging Out

* Press `Ctrl + Alt + Del` → **Sign out**, then log back in.

### Restart the Computer

* Click **Start** → **Power** → **Restart**.
* Or run in PowerShell:

  ```powershell
  Restart-Computer
  ```

---

## 🖱 Usage

Right-click a file/folder → choose **Copy Relative Path** or **Copy Absolute Path** → paste anywhere.

---

## ⚙ Customization

Edit `Copy-PortablePath.ps1`:

* Change `$BasePath` to adjust relative path root
* Change separator style by modifying:

  ```powershell
  $PortablePath = $Path -replace '\\','/'
  ```

---

## 🔄 Uninstallation

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
C:/path/to/uninstall.ps1
```

Or right-click → **Run with PowerShell**.

Restart Explorer or the system using any method above.

---

## 🛠 Troubleshooting

| Issue              | Cause                       | Fix                              |
| ------------------ | --------------------------- | -------------------------------- |
| Menu items missing | Registry not applied        | Restart File Explorer            |
| Clipboard empty    | Clipboard blocked by policy | Copy output manually             |
| Wrong path format  | Script separator setting    | Update `$PortablePath` in script |

---

## 📜 License

GPL-3.0-or-later © 2025 Moko Consulting

---

## 👨‍💻 Developer Notes

* Tested on Windows 11
* Portable and network-share friendly
* Documentation and scripts built with ChatGPT assistance
