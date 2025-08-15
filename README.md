# Copy-PortablePath

Copy-PortablePath is a PowerShell utility that adds right-click context menu options to copy either the **relative** or **absolute** file/folder path in a portable, forward-slash-friendly format.

## Features

- **Copy Relative Path** — Gets the path relative to the current working directory.
- **Copy Absolute Path** — Gets the full path of the selected item.
- Works for files and folders.
- Supports multiple file selection.
- Output uses forward slashes for portability across systems.

## Requirements

- Windows 10/11
- PowerShell 5.1 or later (PowerShell 7+ supported)
- Administrator rights required for system-wide installation.

---

## Installation

### 1. Download the Repository

Clone or download this repository to your local system.

### 2. Open PowerShell in the Project Folder

```powershell
cd "path\\to\\Copy-PortablePath"
```

### 3. Run the Installer

#### For All Users (requires admin):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1 -Scope Machine
```

#### For Current User Only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install.ps1 -Scope User
```

After installation, right-click any file or folder in File Explorer to see the new options:

- **Copy Relative Path**
- **Copy Absolute Path**

---

## Uninstallation

### 1. Open PowerShell in the Project Folder

```powershell
cd "path\\to\\Copy-PortablePath"
```

### 2. Run the Uninstaller

#### For All Users (requires admin):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\uninstall.ps1 -Scope Machine
```

#### For Current User Only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\uninstall.ps1 -Scope User
```

Once uninstalled, the context menu options will be removed.

---

## Troubleshooting

- If scripts are blocked, ensure execution policy is set to allow running local scripts:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

- Ensure you are running PowerShell **as Administrator** when installing/uninstalling in `Machine` scope.
- Check the `install.log` file in the project folder for errors.

---

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for details.

---

**Author:** Jonathan Andrew Miller (Moko Consulting)\
**Contact:** [hello@mokoconsulting.tech](mailto\:hello@mokoconsulting.tech)

