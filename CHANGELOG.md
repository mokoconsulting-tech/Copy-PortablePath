<!--
Copyright (C) 2025 Moko Consulting <hello@mokoconsulting.tech>

This file is part of a Moko Consulting project.

This documentation is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This documentation is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this documentation. If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: GPL-3.0-or-later
-->
# Copy-PortablePath - CHANGELOG.md

All notable changes to **Copy-PortablePath** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> Dates are in **America/Chicago** time. Current date: **2025-08-13**.

---

## [Unreleased]

### Added

* Initial public release of **Copy-PortablePath**.
* Explorer context menu entries for **Copy Relative Path** and **Copy Absolute Path**.
* Option to copy **POSIX-style paths** (forward slashes) while preserving drive letters.
* Setting to **quote paths** automatically when they contain spaces.
* Optional **trailing newline suppression** toggle for clipboard text.
* **Multi-select** support for copying multiple items as a newline-delimited list.
* Context menu entries for **background of folders** (empty area) to copy the current directory path.
* Support for copying paths of both **files** and **directories**.
* Registry template generation relative to the current folder for portable installs.
* `install.ps1` and `uninstall.ps1` helper scripts to register/unregister all menu items and file-type bindings.
* PowerShell implementation to compute paths relative to the active directory or selected item root.
